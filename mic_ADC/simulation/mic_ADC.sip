set_global_assignment -entity "mic_ADC" -library "lib_mic_ADC" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "mic_ADC" -library "lib_mic_ADC" -name IP_TOOL_VERSION "23.1"
set_global_assignment -entity "mic_ADC" -library "lib_mic_ADC" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_mic_ADC" -name SPD_FILE [file join $::quartus(sip_path) "../mic_ADC.spd"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "../../mic_ADC.qsys"]

set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "mic_ADC.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_up_avalon_adv_adc.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control_avrg_fifo.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control_fsm.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sample_store.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sample_store_ram.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sequencer.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sequencer_csr.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sequencer_ctrl.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/chsel_code_converter_sw_to_hw.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/DE10_Lite_ADC_Core_modular_adc_0.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fiftyfivenm_adcblock_primitive_wrapper.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fiftyfivenm_adcblock_top_wrapper.v"]
set_global_assignment -library "lib_mic_ADC" -name MISC_FILE [file join $::quartus(sip_path) "submodules/mic_ADC_adc_mega_0.v"]
