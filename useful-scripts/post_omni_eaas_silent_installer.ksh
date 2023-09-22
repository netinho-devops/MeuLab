#!/bin/ksh

#--------------------------------------------------------------------
##=Name post_omni_eaas_silent_installer.ksh
##
##=Purpose - Post installation of omni on eaas
##
##=Parameters - none
##
##=Author - Devendra Hupri
##
##=Date 02-Dec-2015
##
##=Updates and Fixes History
## --- Owner --- | --- Date --- | ------- Description ---------------
##               |              |
##               |              |
#--------------------------------------------------------------------

# --------- OMNI SIDE ASC CHANGES --------------- #

/vivnas/viv/vivtools/Scripts/OMNI_Scripts/omni_post_changes.ksh


# ------ OMS CHANGES AND SEC ROLE UPDATE -------- #

/vivnas/viv/vivtools/Scripts/OMNI_Scripts/oms_and_sec_role_changes.ksh
