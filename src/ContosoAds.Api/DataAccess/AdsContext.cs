using ContosoAds.Api.Model;
using Microsoft.AspNetCore.DataProtection.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace ContosoAds.Api.DataAccess;

public class AdsContext : DbContext, IDataProtectionKeyContext
{
    public AdsContext(DbContextOptions<AdsContext> options) : base(options)
    {
    }

    public DbSet<Ad> Ads => Set<Ad>();
    public DbSet<DataProtectionKey> DataProtectionKeys => Set<DataProtectionKey>(); 
}