proc draw_waveform {WFfile WFname WFlabel Option} {
	# needed to support files with spaces
	set WF [string map {"\"" ""} $WFfile]
	dataset open "$WF"
	set WF [file tail "$WF"]
	set WF [string map {".csv" ""} $WF]    

	set wfn "<${WF}>$WFname"
	wfc "WF_str = \"$wfn\""
	set wfdraw [wfc {wf(WF_str)}]
	add wave $Option -zerolevel on -label $WFlabel $wfdraw	
	return $wfdraw
}

proc zoom {DataRateEnv TimeEnv} {
	set DataRate [expr {$DataRateEnv * 1e+6}]	
	set Tclk [expr {1/($DataRate/2)}]
	if {$TimeEnv ne "N/A"} {
		set Tmeas [expr {$TimeEnv * 1e-9}]
		# define Start and End values for zoom
		set Xstart [expr {$Tmeas - $Tclk/1.5}]
		if {$Xstart < 0 } {
			set Xstart 0
		}
		set Xend [expr {$Tmeas + $Tclk/1.5}]
		wave zoomrange $Xstart $Xend
	}
}

proc add_one_horiz_cursor {TMeasDX YthresholdL YthresholdH case} {	
	wfc "ThX = $TMeasDX"
	# get yval for second cursor
	set yval [wfc {yval(wf(WF_str), ThX)}]	
	if {[expr abs($yval - $YthresholdL)] < 0.02} {
		wave addcursor -name ${case}_Low -horizontal -time $YthresholdL
	} elseif {[expr abs($yval - $YthresholdH)] < 0.02} {
		wave addcursor -name ${case}_High -horizontal -time $YthresholdH
	}	
}

proc add_both_horiz_cursors {MeasType YthresholdL YthresholdH} {
	wave addcursor -name ${MeasType}_Low -horizontal -time $YthresholdL
	wave addcursor -name ${MeasType}_High -horizontal -time $YthresholdH
}

proc add_delta_marker {MeasType TmeasX1 TmeasY1 TMeasX2 TMeasY2 MeasX_ps WF1 WF2} {		
	# first wf is  (TmeasX1, TMeasY1)
	# second wf is (TMeasX2, TMeasY2)
	wave adddeltamarker -xdelta -wf1 $WF1 -x1 $TmeasX1 -y1 $TmeasY1 -wf2 $WF2 -x2 $TMeasX2 -y2 $TMeasY2 -text "$MeasType=${MeasX_ps}ps"	
}


if { [info exists env(Thresholds) ] } {
	set ThresholdsStr [string map {"\"" ""} $env(Thresholds)]
}

if {$env(TableType) eq "Skew"}  {
	set temp [split $ThresholdsStr ";"]
	set SkewlabelsStr [lindex $temp 0]
	set Skewlabels [split $SkewlabelsStr "|"]
	set CursorsStr [lindex $temp 1]
	set Cursors [split $CursorsStr "|"]
	set WindowName [lindex $Skewlabels 0]
	append WindowName " - " [lindex $Skewlabels 1]
	wave closewindow -all
	wave addwindow -title $WindowName
	set Option "-append"
	set i 0		
	foreach label $Skewlabels {
		set Cursor [lindex $Cursors $i]
		set Tmeas [expr {$Cursor * 1e-9}]
		incr i
		set WF_name [string map {"\"" ""} $env(WFname$i)]		
		set WF_label "$label=$WF_name"				
		if {$i == 3} {				
			zoom $env(DataRate) $env(Time)
			set WindowName $label
			append WindowName " - " [lindex $Skewlabels 3]
			wave addwindow -title $WindowName			
		}
		draw_waveform $env(WFfile$i) $WF_name $WF_label $Option
		wave addcursor -name $label -time $Tmeas
	}
	zoom $env(DataRate) $env(Time)	
	if {$i == 4} {
		wave tile -horizontal
	}		
} else {
	set WF_name1 [string map {"\"" ""} $env(WFname1)]
	set WF1_label "$WF_name1"	
	# load the second waveform first
	if { [info exists env(WFfile2) ] } {  
		set WF_name2 [string map {"\"" ""} $env(WFname2)]
		# labels
		if {$env(TableType) eq "Data"} {
			set WF2_label "DQS=$WF_name2"
			set WF1_label "DQ=$WF_name1"
		} elseif {$env(TableType) eq "Address"} {
			set WF2_label "CLK=$WF_name2"
			set WF1_label "ADDR=$WF_name1"
		} elseif {$env(TableType) eq "Differential"} {
			set WF2_label "CLK=$WF_name2"
			set WF1_label "DQS=$WF_name1"
		} elseif {$env(TableType) eq "Diff_Vix"} {
			set WF2_label "Opp=$WF_name2"
			set WF1_label "Main=$WF_name1"
		}
		set WF2 [draw_waveform $env(WFfile2) $WF_name2 $WF2_label ""]
		if {$env(Time) ne "N/A"} {
			set TMeasX [expr {$env(Time) * 1e-9}]
			wfc "TmX = $TMeasX"
			set TMeasY1 [wfc {yval(wf(WF_str), TmX)}]
		}
	}
	set Option "-append"
	
	# Vix handled differently
	if {$env(TableType) eq "Diff_Vix"} {
		set Option "-append"	
	}

	# draw first waveform
	set WF1 [draw_waveform $env(WFfile1) $WF_name1 $WF1_label $Option]
		
	# add threshold cursors
	set MeasX_ps ""
	if { [info exists env(Thresholds) ] } {			
		set fields [split $ThresholdsStr ";"]
		set MeasType [lindex $fields 0]
		set YthresholdH [lindex $fields 1]
		set YthresholdL [lindex $fields 2]	
		set ListLength [llength $fields]
		if {$ListLength eq 4} {
			set MeasX_ps [lindex $fields 3]
		}					
		if {$env(Time) ne "N/A"} {
			# Threshold time
			set TMeasX1 [expr {$env(Time) * 1e-9}]
			if {$MeasType eq "Setup" || $MeasType eq "Hold"} {				
				if {$MeasX_ps ne ""} {
					if {$MeasType eq "Setup"} {
						set TMeasX2 [expr {$TMeasX1 - $MeasX_ps * 1e-12}]
					} else {
						set TMeasX2 [expr {$TMeasX1 + $MeasX_ps * 1e-12}]
					}					
					add_one_horiz_cursor $TMeasX2 $YthresholdL $YthresholdH $MeasType
					wfc "TmX2 = $TMeasX2"
					set TMeasY2 [wfc {yval(wf(WF_str), TmX2)}]
					add_delta_marker $MeasType $TMeasX1 $TMeasY1 $TMeasX2 $TMeasY2 $MeasX_ps $WF2 $WF1
				} else {
					add_both_horiz_cursors $MeasType $YthresholdL $YthresholdH
				}
			} 	
		} else {
			add_both_horiz_cursors $MeasType $YthresholdL $YthresholdH
		}
	} elseif {$env(Time) ne "N/A"} {
		set TMeasX1 [expr {$env(Time) * 1e-9}]
		wave addcursor -name Threshold -time $TMeasX1				
	}	
	zoom $env(DataRate) $env(Time)
} 
if { [info exists env(EZWave_IMG_Path) ] } {
	# write png $env(EZWave_IMG_Path) -colorasdisplayed -visiblewindows -resolution printerlow
	write png $env(EZWave_IMG_Path) -colorasdisplayed -visiblewindows
	dataset close -all
}
