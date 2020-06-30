$DomainName = "example-gcp.com"
$AdminUserName = "Administrator"
$gMSAGroupName = "GRP1"

function Overwrite-KubeServices-Hostname {
  $instanceName = Invoke-RestMethod -Headers @{'Metadata-Flavor'='Google'} -Uri 'http://metadata.google.internal/computeMetadata/v1/instance/name'

  Write-Information "Changing kubelet hostname to $instanceName" -InformationAction Continue
  $kubeletPath = Get-WmiObject win32_service | ?{$_.Name -like 'kubelet'} | select PathName
  $kubeletPath = $kubeletPath.PathName
  Write-Information "Got kubelet path = $kubeletPath" -InformationAction Continue
  sc.exe config kubelet binPath="$kubeletPath --hostname-override=$instanceName"
  $kubeletPath = Get-WmiObject win32_service | ?{$_.Name -like 'kubelet'} | select PathName
  $kubeletPath = $kubeletPath.PathName
  Write-Information "New kubelet path = $kubeletPath" -InformationAction Continue

  Write-Information "Changing kube-proxy hostname to $instanceName" -InformationAction Continue
  $kubeproxyPath = Get-WmiObject win32_service | ?{$_.Name -like 'kube-proxy'} | select PathName
  $kubeproxyPath = $kubeproxyPath.PathName
  Write-Information "Got kube-proxy path = $kubeproxyPath" -InformationAction Continue
  sc.exe config kube-proxy binPath="$kubeproxyPath --hostname-override=$instanceName"
  $kubeproxyPath = Get-WmiObject win32_service | ?{$_.Name -like 'kube-proxy'} | select PathName
  $kubeproxyPath = $kubeproxyPath.PathName
  Write-Information "New kube-proxy path = $kubeproxyPath" -InformationAction Continue
}

function Add-MachineToDomain {
  $partOfDomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain

  if(-Not($partOfDomain)) {
    Write-Information "Machine not part of domain. Adding it to the domain $DomainName" -InformationAction Continue

    Overwrite-KubeServices-Hostname

    $NewName = "GKE-$(Get-Random)"
    Write-Information "Adding machine $NewName to the domain and restarting" -InformationAction Continue
    
    Rename-Computer -NewName $NewName

    $psCred = Get-Credential
    Write-Information "Got credential"  -InformationAction Continue
    Add-Computer -DomainName $DomainName -Credential $psCred -Restart -InformationAction Continue
  } else {
    Write-Information "Machine already part of domain" -InformationAction Continue
  }
}

Add-MachineToDomain
