class cacheObject
{
    [pageResponse]$response
    [datetime]$expires
    
    cacheObject([pageResponse]$response,[int]$cacheTime)
    {
        $this.response = $response
        $this.expires = $(get-date).AddMinutes($cacheTime)
    }
}