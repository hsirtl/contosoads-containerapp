using System.ComponentModel.DataAnnotations;

namespace ContosoAds.Api.Model;

public enum Category
{
    Cars,
    [Display(Name = "Real Estate")]
    RealEstate,
    [Display(Name = "Free Stuff")]
    FreeStuff
}