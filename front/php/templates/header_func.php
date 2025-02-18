<?php

// Delete WebGUI Reports ---------------------------------------------------------------

function useRegex($input) {
	$regex = '/[0-9]+-[0-9]+_.*\\.txt/i';
	return preg_match($regex, $input);
}

function count_webgui_reports() {
	if (isset($_REQUEST['remove_report'])) {
		$prep_remove_report = str_replace(array('\'', '"', ',', ';', '<', '>', '.', '/', '&'), "", $_REQUEST['remove_report']) . '.txt';
		if (useRegex($prep_remove_report) == TRUE) {
			if (file_exists('./reports/' . $prep_remove_report)) {
				unlink('./reports/' . $prep_remove_report);
			}
		}
	}

	$files = array_diff(scandir('./reports'), array('..', '.', 'download_report.php'));
	$report_counter = count($files);
	if ($report_counter == 0) {unset($report_counter);}
	return $report_counter;
}

// Pause Arp Scan Section ---------------------------------------------------------------

function arpscanstatus() {
	global $pia_lang;
	if (!file_exists('../db/setting_stoparpscan')) {
		$execstring = 'ps aux | grep "~/pialert/back/pialert.py 1" 2>&1';
		$pia_arpscans = "";
		exec($execstring, $pia_arpscans);
		unset($_SESSION['arpscan_timerstart']);
		$_SESSION['arpscan_result'] = sizeof($pia_arpscans) - 2 . ' ' . $pia_lang['Maintenance_arp_status_on'];
		$_SESSION['arpscan_sidebarstate'] = 'Active';
		$_SESSION['arpscan_sidebarstate_light'] = 'green-light fa-gradient-green';
	} else {
		$_SESSION['arpscan_timerstart'] = date("H:i:s", filectime('../db/setting_stoparpscan'));
		$_SESSION['arpscan_result'] = '<span style="color:red;">arp-Scan ' . $pia_lang['Maintenance_arp_status_off'] . '</span>';
		$_SESSION['arpscan_sidebarstate'] = 'Disabled&nbsp;&nbsp;&nbsp;(' . $_SESSION['arpscan_timerstart'] . ')';
		$_SESSION['arpscan_sidebarstate_light'] = 'red fa-gradient-red';
	}
}

// Systeminfo in Sidebar ---------------------------------------------------------------
function getTemperature() {
	if (file_exists('/sys/class/thermal/thermal_zone0/temp')) {
		$output = rtrim(file_get_contents('/sys/class/thermal/thermal_zone0/temp'));
	} elseif (file_exists('/sys/class/hwmon/hwmon0/temp1_input')) {
		$output = rtrim(file_get_contents('/sys/class/hwmon/hwmon0/temp1_input'));
	} else {
		$output = '';
	}

	// Test if we succeeded in getting the temperature
	if (is_numeric($output)) {
		// $output could be either 4-5 digits or 2-3, and we only divide by 1000 if it's 4-5
		// ex. 39007 vs 39
		$celsius = intval($output);
		// If celsius is greater than 1 degree and is in the 4-5 digit format
		if ($celsius > 1000) {
			// Use multiplication to get around the division-by-zero error
			$celsius *= 1e-3;
		}
		$limit = 60;

	} else {
		// Nothing can be colder than -273.15 degree Celsius (= 0 Kelvin)
		// This is the minimum temperature possible (AKA absolute zero)
		$celsius = -273.16;
		// Set templimit to null if no tempsensor was found
		$limit = null;
	}
	return array($celsius, $limit);
}

function getMemUsage() {
	$data = explode("\n", file_get_contents('/proc/meminfo'));
	$meminfo = array();
	if (count($data) > 0) {
		foreach ($data as $line) {
			$expl = explode(':', $line);
			if (count($expl) == 2) {
				// remove " kB" from the end of the string and make it an integer
				$meminfo[$expl[0]] = intval(trim(substr($expl[1], 0, -3)));
			}
		}
		$memused = $meminfo['MemTotal'] - $meminfo['MemFree'] - $meminfo['Buffers'] - $meminfo['Cached'];
		$memusage = $memused / $meminfo['MemTotal'];
	} else {
		$memusage = -1;
	}
	return $memusage;
}

function format_MemUsage($memory_usage) {
	echo '<span><i class="fa fa-w fa-circle ';
	if ($memory_usage > 0.75 || $memory_usage < 0.0) {
		echo 'text-red fa-gradient-red';
	} else {
		echo 'text-green-light fa-gradient-green';
	}
	if ($memory_usage > 0.0) {
		echo '"></i> Memory usage:&nbsp;&nbsp;' . sprintf('%.1f', 100.0 * $memory_usage) . '&thinsp;%</span>';
	} else {
		echo '"></i> Memory usage:&nbsp;&nbsp; N/A</span>';
	}
}

function format_sysloadavg($loaddata) {
	$nproc = shell_exec('nproc');
	if (!is_numeric($nproc)) {
		$cpuinfo = file_get_contents('/proc/cpuinfo');
		preg_match_all('/^processor/m', $cpuinfo, $matches);
		$nproc = count($matches[0]);
	}
	echo '<span title="Detected ' . $nproc . ' cores"><i class="fa fa-w fa-circle ';
	if ($loaddata[0] > $nproc) {
		echo 'text-red fa-gradient-red';
	} else {
		echo 'text-green-light fa-gradient-green';
	}
	echo '"></i> Load:&nbsp;&nbsp;' . round($loaddata[0], 2) . '&nbsp;&nbsp;' . round($loaddata[1], 2) . '&nbsp;&nbsp;' . round($loaddata[2], 2) . '</span>';
}

function format_temperature($celsius, $temperaturelimit) {
	if ($celsius >= -273.15) {
		// Only show temp info if any data is available -->
		$tempcolor = 'text-vivid-blue';
		if (isset($temperaturelimit) && $celsius > $temperaturelimit) {
			$tempcolor = 'text-red fa-gradient-red';
		}
		echo '<span id="temperature"><i class="fa fa-w fa-fire ' . $tempcolor . '" style="width: 1em !important"></i> ';
		echo 'Temp:&nbsp;<span id="rawtemp" hidden>' . $celsius . '</span>';
		echo '<span id="tempdisplay"></span></span>';
	}
}
// Web Services Menu Items ---------------------------------------------------------------
function toggle_webservices_menu($section) {
	global $pia_lang;
	if (($_SESSION['Scan_WebServices'] == True) && ($section == "Main")) {
		echo '<li class="';
		if (in_array(basename($_SERVER['SCRIPT_NAME']), array('services.php', 'serviceDetails.php'))) {echo 'active';}
		echo '">
                <a href="services.php"><i class="fa fa-globe"></i> <span>' . $pia_lang['Navigation_Services'] . '</span></a>
              </li>';
		echo '<li class="header text-uppercase" style="font-size: 0; padding: 1px;">EVENTS</li>';
	}

	if (($_SESSION['Scan_WebServices'] == True) && ($section == "Event")) {
		echo '<li class="';
		if (in_array(basename($_SERVER['SCRIPT_NAME']), array('servicesEvents.php'))) {echo 'active';}
		echo '">
              <a href="servicesEvents.php"><i class="fa fa-globe"></i> <span>' . $pia_lang['Navigation_Events_Serv'] . '</span></a>
            </li>';
	}
}
// Web Services Config ---------------------------------------------------------------
function get_webservices_config() {
	$config_file = "../config/pialert.conf";
	$config_file_lines = file($config_file);
	$config_file_lines_bypass = array_values(preg_grep('/^SCAN_WEBSERVICES\s.*/', $config_file_lines));
	$scan_services_line = explode("=", $config_file_lines_bypass[0]);
	if (strtolower(trim($scan_services_line[1])) == "true") {
		$_SESSION['Scan_WebServices'] = True;
	} else { $_SESSION['Scan_WebServices'] = False;}
}

// Back button for details pages ---------------------------------------------------------------
function insert_back_button() {
	$pagename = basename($_SERVER['PHP_SELF']);

	if ($pagename == 'serviceDetails.php') {
		$backto = 'services.php';
	}

	if ($pagename == 'deviceDetails.php') {
		$backto = 'devices.php';
	}

	if (isset($backto)) {
		echo '<a id="navbar-back-button" href="./' . $backto . '" role="button" style="">
        <i class="fa fa-chevron-left"></i>
      </a>';
	}
}

// Adjust Logo Color ---------------------------------------------------------------
function set_iconcolur_for_skin($skinname) {
	//echo $skinname;
	//$PIALERTLOGO_LINK = 'pialertLogoWhite';
	if ($skinname == 'skin-black-light' || $skinname == 'skin-black') {
		return 'pialertLogoBlack';
	} else {return 'pialertLogoWhite';}

}
?>