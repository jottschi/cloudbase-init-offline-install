$ErrorActionPreference = "Stop"

function Invoke-FastWebRequest
{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True,ValueFromPipeline=$true,Position=0)]
    [System.Uri]$Uri,
    [Parameter(Mandatory=$True,Position=1)]
    [string]$OutFile
    )
    PROCESS
    {
        $assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Net.Http")

        $client = new-object System.Net.Http.HttpClient
        $task = $client.GetAsync($Uri)
        $task.wait()
        $response = $task.Result
        $status = $response.EnsureSuccessStatusCode()

        $outStream = New-Object IO.FileStream $OutFile, Create, Write, None

        try
        {
            $task = $response.Content.ReadAsStreamAsync()
            $task.Wait()
            $inStream = $task.Result

            $contentLength = $response.Content.Headers.ContentLength

            $totRead = 0
            $buffer = New-Object Byte[] 1MB
            while (($read = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0)
            {
                $totRead += $read
                $outStream.Write($buffer, 0, $read);

                if($contentLength)
                {
                    $percComplete = $totRead * 100 / $contentLength
                    Write-Progress -Activity "Downloading: $Uri" -PercentComplete $percComplete
                }
            }
        }
        finally
        {
            $outStream.Close()
        }
    }
}

