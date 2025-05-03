$natSwitchName = "NATSwitch"
$natRouterAddress = "192.168.200.1"
$natNetwork = "192.168.200.0"
$natPrefixLength = "24"
$natNetworkFull = $natNetwork + "/" + $natPrefixLength

# Создаем новый коммутатор в Hyper-V (и соответственно новый сетевой адаптер в ОС)
New-VMSwitch -SwitchName $natSwitchName -SwitchType Internal -Verbose

# Получаем все параметры созданного сетевого адаптера и сохраняем их в переменную
$natSwitch = Get-NetAdapter | where {(($_.name -like ("vEthernet ($natSwitchName)")))}

# Вешаем на наш новый интерфейс IP-адрес
New-NetIPAddress $natRouterAddress -PrefixLength $natPrefixLength -InterfaceIndex $natSwitch.interfaceindex -Verbose

# Создаем новую NAT-сеть
New-NetNat -Name HyperV-NatNetwork -InternalIPInterfaceAddressPrefix $natNetworkFull -Verbose
