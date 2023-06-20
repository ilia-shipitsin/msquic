Import-Module ImageHelpers


Function Install-VisualStudioCustom
{
    <#
    .SYNOPSIS
        A helper function to install Visual Studio.

    .DESCRIPTION
        Prepare system environment, and install Visual Studio bootstrapper with selected workloads.

    .PARAMETER BootstrapperUrl
        The URL from which the bootstrapper will be downloaded. Required parameter.

    .PARAMETER WorkLoads
        The string that contain workloads that will be passed to the installer.
    #>

    Param
    (
        [Parameter(Mandatory)]
        [String] $BootstrapperUrl,
        [String] $WorkLoads
    )

    try
    {
        Write-Host "Enable short name support on Windows needed for Xamarin Android AOT, defaults appear to have been changed in Azure VMs"
        $shortNameEnableProcess = Start-Process -FilePath fsutil.exe -ArgumentList ('8dot3name', 'set', '0') -Wait -PassThru

        $shortNameEnableExitCode = $shortNameEnableProcess.ExitCode
        if ($shortNameEnableExitCode -ne 0)
        {
            Write-Host "Enabling short name support on Windows failed. This needs to be enabled prior to VS 2017 install for Xamarin Andriod AOT to work."
            exit $shortNameEnableExitCode
        }

        Write-Host "Starting Install ..."
        $bootstrapperArgumentList = ('/c', "vs_installer.exe", $WorkLoads, '--quiet', '--norestart', '--nocache' )
        Set-Location "C:\Program Files (x86)\Microsoft Visual Studio\Installer\"
        $process = Start-Process -FilePath cmd.exe -ArgumentList $bootstrapperArgumentList -Wait -PassThru

        $exitCode = $process.ExitCode
        if ($exitCode -eq 0 -or $exitCode -eq 3010)
        {
            Write-Host "Installation successful"
            return $exitCode
        }
        else
        {
            $l = Get-ChildItem -Path ${env:TEMP} -Filter 'dd*'
            foreach($log in $l)
            {
                Write-Host $log.FullName
                Write-Host '----------------------'
                $logErrors = Get-Content -Path $log.FullName -Raw
                Write-Host "$logErrors"

            }

            Write-Host "Non zero exit code returned by the installation process : $exitCode"
            exit $exitCode
        }
    }
    catch
    {
        Write-Host "Failed to install Visual Studio; $($_.Exception.Message)"
        exit -1
    }
}

$workLoads = @(
            "modify"
            "--productID Microsoft.VisualStudio.Product.Enterprise"
            "--channelId VisualStudio.17.Release"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ARM"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ARM.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ARM64"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ARM64.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.x86.x64"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.x86.x64.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ATL"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ATL.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ATL.ARM"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ATL.ARM.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ATL.ARM64"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.ATL.ARM64.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.MFC"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.MFC.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.MFC.ARM"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.MFC.ARM.Spectre"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.MFC.ARM64"
            "--add Microsoft.VisualStudio.Component.VC.14.35.17.5.MFC.ARM64.Spectre"
)

$workLoadsArgument = [String]::Join(" ", $workLoads)

$toolset = Get-ToolsetContent

$releaseInPath = $toolset.visualStudio.edition
$subVersion = $toolset.visualStudio.subversion
$channel = $toolset.visualStudio.channel
$bootstrapperUrl = "https://aka.ms/vs/${subVersion}/${channel}/vs_${releaseInPath}.exe"

Install-VisualStudioCustom -BootstrapperUrl $bootstrapperUrl -WorkLoads $workLoadsArgument

