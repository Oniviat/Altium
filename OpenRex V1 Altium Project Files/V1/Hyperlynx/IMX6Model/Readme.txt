Revision 1.4 updates:

This model is based on cln40lp_io51u50dgo8m5x0y2z_fc_1.0p3,fix something:

1.Separated ddr address+cmd+ctl+dqm (set as ddr_non_odt) from others for simulation

2.Set "JTAG_xx,POR_B,ONOFF,BOOTMODE0/1,PMIC_ON_REQ, PMIC_STBY_REQ ,TAMPER, TEST_MODE " signals to model 'NC'. 
  These signals are DC signals.  
  Set "CLK1_P/N and CLK2_P/N"signals to model 'LVDS'.

3.Deleted the model of usb_vbus_input and change the related signal to NC.(cause we think that customers do not need it).
  This signal is a DC signal.

4.Corrected SATA_TXM, SATA_RXP, SATA_REXT, VDD_SNVS_CAP, VDDARM23_CAP, HDMI_VP, HDMI_VPH signals.

5.Changed the model_name of USB_H1_VBUS and USB_OTG_VBUS from NC to POWER. 

