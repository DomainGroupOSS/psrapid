#Should we cache
#If so for how long should we cache
#Should we hide the link
#Should we restrict to CIDR
#Need a CIDR Helper
#Should be an attribute
#should cacheControl be separate from the functionControls?
#Needs more thought
#Auth Groups
#Should be in the page class


class PageControl : System.Attribute
{
    [int] $cacheMins
    [bool] $cache
    [array] $networkRange
    [array] $authGroup
    [bool] $tokenRequired
    
    PageControl()
    {
    }

}