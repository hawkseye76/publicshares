$movies_folder = "T:\path\to\downloaded\movie"  # Path to where movies are going to land for conversion
$destination_folder = "T:\path\to\destination" # Path to where going to be sent for final Plex consumption

If ((Get-ChildItem $movies_folder -Recurse -Include *.mkv,*.mp4).Count -eq 0)
{
    exit
}

#Filebot requries a license.  https://www.filebot.net/

$filebot_result = Start-Process "C:\Program Files\FileBot\filebot.exe" -ArgumentList "-rename T:\Complete\Movies\ -r --format `"{n} ({y})`" --db TheMovieDB -non-strict" -RedirectStandardOutput C:\WorkArea\movies_filebot.txt -Wait -PassThru

$files = Get-ChildItem $movies_folder -Recurse -Include *.mkv,*.mp4

foreach ($file in $files)
{
    #if you only want to encode between certain hours
    #if (((Get-Date).Hour -ge 0 -and (Get-Date).Hour -le 6)) {  } else { break }

    $source = $file.FullName
    $destination = "$($destination_folder)\$($file.BaseName)\$($file.BaseName).mp4"
    
    if (!(Test-Path "$($destination_folder)\$($file.BaseName)"))
    {
        New-Item -ItemType Directory -Path "$($destination_folder)\$($file.BaseName)" -Force
    }

    #uses handbrakeclie to do encoding - https://handbrake.fr/downloads2.php

    $handbrake_result = Start-Process "C:\HandBrakeCLI\HandBrakeCLI.exe" -ArgumentList "-Z `"Roku 1080p30 Surround`" --optimize -i `"$($source)`" -o `"$($destination)`"" -Wait -PassThru
    #$handbrake_result = Start-Process "C:\HandBrakeCLI\HandBrakeCLI.exe" -ArgumentList "-Z `"Roku 2160p60 4K HEVC Surround`" --optimize -i `"$($source)`" -o `"$($destination)`"" -Wait -PassThru
    

    if ($handbrake_result.ExitCode -eq 0)
    {
        Remove-Item -Path $file.FullName -Confirm:$false -Recurse -Force
    }
    
}

# Clean up empty folders
Write-Host "Cleaning Up Empty Folders"
# Clean up non .mp4 or .mkv files
Get-ChildItem $movies_folder -Recurse -Exclude *.mkv,*.mp4 -File | Remove-Item
Get-ChildItem $movies_folder -recurse | ? {$_.PSIsContainer -and @(Get-ChildItem -LiteralPath:$_.fullname).Count -eq 0} | Remove-Item -Confirm:$false -Force
