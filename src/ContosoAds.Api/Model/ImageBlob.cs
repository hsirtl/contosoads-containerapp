using System.ComponentModel.DataAnnotations;

namespace ContosoAds.Api.Model;

public record ImageBlob([Required] Uri Uri, [Required] int AdId);