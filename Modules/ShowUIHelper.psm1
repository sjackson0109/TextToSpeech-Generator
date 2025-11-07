# ShowUI Helper Module for TextToSpeech Generator
# Provides functions to convert XAML to ShowUI controls, and build GUI programmatically

Import-Module ShowUI -ErrorAction Stop

function Show-TTSGeneratorGUI {
    [CmdletBinding()]
    param(
        [string]$Profile = "Default"
    )
    New-Window -Title "TextToSpeech Generator" -Width 900 -Height 800 -Background "#232323" -Content {
        New-ScrollViewer -VerticalScrollBarVisibility Auto -HorizontalScrollBarVisibility Auto -Content {
            New-StackPanel -Margin 16 -Children {
                # Header
                New-Border -Background "#2D2D30" -CornerRadius 6 -Padding 12 -Margin "0,0,0,12" -Child {
                    New-StackPanel -Children {
                        New-TextBlock -Text "🎤 TextToSpeech Generator" -FontSize 20 -FontWeight Bold -Foreground White
                        New-TextBlock -Text "Convert text to high-quality speech using enterprise TTS providers. Save API configurations and switch between providers seamlessly." -FontSize 12 -Foreground "#CCCCCC" -Margin "0,4,0,0" -TextWrapping Wrap
                    }
                }
                # TTS Provider Selection
                New-GroupBox -Header "TTS Provider Selection" -Foreground White -Margin "0,0,0,12" -Content {
                    New-StackPanel -Children {
                        New-Grid -Margin 8 -ColumnDefinitions @(180,"*",110,110) -Children {
                            New-Label -Content "Provider:" -GridColumn 0 -VerticalAlignment Center -Foreground White
                            New-ComboBox -Name "ProviderSelect" -GridColumn 1 -Height 25 -Margin "5,2" -VerticalAlignment Center -Items @("Azure","AWS","Google","Twilio","VoiceForge","VoiceWave")
                            New-Button -Content "Refresh" -GridColumn 2 -Height 25 -Margin "5,2" -VerticalAlignment Center
                            New-Button -Content "Setup" -GridColumn 3 -Height 25 -Margin "5,2" -VerticalAlignment Center
                        }
                    }
                }
                # Add more controls here as needed
            }
        }
    } -Show
}

Export-ModuleMember -Function Show-TTSGeneratorGUI
