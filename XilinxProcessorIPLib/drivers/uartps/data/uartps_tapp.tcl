###############################################################################
#
# Copyright (C) 2011 - 2014 Xilinx, Inc.  All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# Use of the Software is limited solely to applications:
# (a) running on a Xilinx device, or
# (b) that interact with a Xilinx device through a bus or interconnect.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
# OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Except as contained in this notice, the name of the Xilinx shall not be used
# in advertising or otherwise to promote the sale, use or other dealings in
# this Software without prior written authorization from Xilinx.
#
###############################################################################
###############################################################################
# MODIFICATION HISTORY:
# Ver      Who    Date     Changes
# -------- ------ -------- ------------------------------------
# 2.0      adk    12/10/13 Updated as per the New Tcl API's
# 3.1      mus    01/14/16 Added support for microblaze
##############################################################################

# Uses $XILINX_EDK/bin/lib/xillib_sw.tcl

# -----------------------------------------------------------------
# Software Project Types (swproj):
#   0 : MemoryTest - Calls basic  memorytest routines from common driver dir
#   1 : PeripheralTest - Calls any existing polled_example and/or selftest
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# TCL Procedures:
# -----------------------------------------------------------------

proc gen_include_files {swproj mhsinst} {
  if {$swproj == 0} {
    return
  }
  if {$swproj == 1} {
    set stdout [common::get_property CONFIG.STDOUT [hsi::get_os]]
    set isStdout [string match $stdout $mhsinst]
    if {${isStdout} == 0} {
        set inc_file_lines { xuartps.h uartps_header.h }
	set isintr [::hsi::utils::is_ip_interrupting_current_proc $mhsinst]
	if {$isintr == 1} {
		set inc_file_lines {xuartps.h uartps_header.h uartps_intr_header.h }
	}
        return $inc_file_lines
    }

    return ""
  }
}

proc gen_src_files {swproj mhsinst} {
  if {$swproj == 0} {
    return ""
  }
  if {$swproj == 1} {
	set stdout [common::get_property CONFIG.STDOUT [hsi::get_os]]
	set isStdout [string match $stdout $mhsinst]
    if {${isStdout} == 0} {
            set inc_file_lines {examples/xuartps_polled_example.c data/uartps_header.h }
	    set isintr [::hsi::utils::is_ip_interrupting_current_proc $mhsinst]
	    if {$isintr == 1} {
		set inc_file_lines {examples/xuartps_intr_example.c examples/xuartps_polled_example.c data/uartps_header.h data/uartps_intr_header.h }
	    }
        return $inc_file_lines
    }
  }
    return ""
}

proc gen_testfunc_def {swproj mhsinst} {
  return ""
}

proc gen_init_code {swproj mhsinst} {


 set stdout [common::get_property CONFIG.STDOUT [hsi::get_os]]
 set isStdout [string match $stdout $mhsinst]
 set ipname [common::get_property NAME $mhsinst]
 if {${isStdout} == 0} {
    if {$swproj == 1} {
		set decl "   static XUartPs ${ipname};"
		set inc_file_lines $decl
		return $inc_file_lines
    }
      return ""
  }

}

proc gen_testfunc_call {swproj mhsinst} {

  set ipname [common::get_property NAME $mhsinst]
  set testfunc_call ""

  if {$swproj == 0} {
    return $testfunc_call
  }

  set stdout [common::get_property CONFIG.STDOUT [hsi::get_os]]
  set isStdout [string match $stdout $mhsinst]
  if {${isStdout} == 1} {
    append testfunc_call "
   /*
    * Peripheral Test will not be run for ${ipname}
    * because it has been selected as the STDOUT device
    */
"
    return $testfunc_call
  }

  set deviceid [::hsi::utils::get_ip_param_name $mhsinst "DEVICE_ID"]
  set stdout [common::get_property CONFIG.STDOUT [hsi::get_os]]
  if { $stdout == "" || $stdout == "none" } {
     set hasStdout 0
  } else {
     set hasStdout 1
  }

  set isintr [::hsi::utils::is_ip_interrupting_current_proc $mhsinst]
  set intcvar intc
  if {$isintr == 1} {
      set intr_pin_name [hsi::get_pins -of_objects [hsi::get_cells -hier $ipname] INTERRUPT]
      set intcname [::hsi::utils::get_connected_intr_cntrl $ipname  $intr_pin_name]
      set proc [get_property IP_NAME [hsi::get_cells -hier [hsi::get_sw_processor]]]
  }


  if {${hasStdout} == 0} {

      append testfunc_call "

   {
      int Status;

      Status = UartPsPolledExample(${deviceid});
   }"

	if {$isintr == 1} {
            if {
                $proc == "microblaze"
            } then {
                    set intr_id "XPAR_${intcname}_${ipname}_${intr_pin_name}_INTR"
            } else {
        set intr_id "XPAR_${ipname}_INTR"
            }
	set intr_id [string toupper $intr_id]

      append testfunc_call "

   {
      int Status;
      Status = UartPsIntrExample(&${intcvar}, &${ipname}, \\
                                  ${deviceid}, \\
                                  ${intr_id});
   }"

   }


  } else {

      append testfunc_call "

   {
      int Status;

      print(\"\\r\\nRunning UartPsPolledExample() for ${ipname}...\\r\\n\");
      Status = UartPsPolledExample(${deviceid});
      if (Status == 0) {
         print(\"UartPsPolledExample PASSED\\r\\n\");
      }
      else {
         print(\"UartPsPolledExample FAILED\\r\\n\");
      }
   }"

	if {$isintr == 1} {
            if {
                $proc == "microblaze"
            } then {
                    set intr_id "XPAR_${intcname}_${ipname}_${intr_pin_name}_INTR"
            } else {
        set intr_id "XPAR_${ipname}_INTR"
            }
	set intr_id [string toupper $intr_id]

	  append testfunc_call "
   {
      int Status;

      print(\"\\r\\n Running Interrupt Test for ${ipname}...\\r\\n\");

      Status = UartPsIntrExample(&${intcvar}, &${ipname}, \\
                                  ${deviceid}, \\
                                  ${intr_id});

      if (Status == 0) {
         print(\"UartPsIntrExample PASSED\\r\\n\");
      }
      else {
         print(\"UartPsIntrExample FAILED\\r\\n\");
      }

   }"

   }

  }
  return $testfunc_call
}
