$natSwitchName = "NATSwitch"
$natNetwork = "192.168.200.0"
$natRouterAddress = "192.168.200.1"
$natPrefixLength = "24"

New-VMSwitch -SwitchName $natSwitchName -SwitchType Internal -Verbose

$natSwitch = Get-NetAdapter | where {(($_.name -like ("vEthernet ($natSwitchName)")))}

New-NetIPAddress $natRouterAddress -PrefixLength $natPrefixLength -InterfaceIndex $natSwitch.interfaceindex -Verbose

$natNetworkFull = $natNetwork + "/" + $natPrefixLength

New-NetNat -Name HyperV-NatNetwork -InternalIPInterfaceAddressPrefix $natNetworkFull -Verbose