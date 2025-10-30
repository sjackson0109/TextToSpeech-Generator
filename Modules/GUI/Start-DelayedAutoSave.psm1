function Start-DelayedAutoSave {
    if ($script:AutoSaveTimer) {
        $script:AutoSaveTimer.Stop()
    }
    
    $script:AutoSaveTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:AutoSaveTimer.Interval = [TimeSpan]::FromSeconds(2)  # 2 second delay
    $script:AutoSaveTimer.add_Tick{
        $script:AutoSaveTimer.Stop()
        Invoke-AutoSaveConfiguration
    }
    $script:AutoSaveTimer.Start()
}

Export-ModuleMember -Function Start-DelayedAutoSave