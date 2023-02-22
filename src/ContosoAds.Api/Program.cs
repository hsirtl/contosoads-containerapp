using ContosoAds.Api;
using ContosoAds.Api.DataAccess;
using ContosoAds.Api.Model;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// change
// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddSingleton<ITelemetryInitializer, TelemetryInitializer>();
builder.Services.AddHealthChecks().AddDbContextCheck<AdsContext>("AdsContext", tags: new[] { "db_ready" });
builder.Services.AddControllers().AddDapr();
builder.Services.AddDbContext<AdsContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        pgOptions => pgOptions.EnableRetryOnFailure(3)));
builder.Services.AddDatabaseDeveloperPageExceptionFilter();
builder.Services.AddDataProtection().PersistKeysToDbContext<AdsContext>();

// Force en-US for a consistent culture.
var supportedCultures = new[] { "en-US" };
var localizationOptions = new RequestLocalizationOptions().SetDefaultCulture(supportedCultures[0])
    .AddSupportedCultures(supportedCultures)
    .AddSupportedUICultures(supportedCultures);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Get all ads
app.MapGet("/ads", async (AdsContext db) =>
    await db.Ads.ToListAsync());

// Get one specific ad
app.MapGet("/ads/{id}", async (int id, AdsContext db) =>
    await db.Ads.FindAsync(id)
        is Ad ad
            ? Results.Ok(ad)
            : Results.NotFound());

// Create a new ad
app.MapPost("/ads", async (Ad ad, AdsContext db) =>
{
    db.Ads.Add(ad);
    await db.SaveChangesAsync();

    return Results.Created($"/ads/{ad.Id}", ad);
});

// Change an ad
app.MapPut("/ads/{id}", async (int id, Ad inputAd, AdsContext db) =>
{
    var ad = await db.Ads.FindAsync(id);

    if (ad is null) return Results.NotFound();

    ad.Title = inputAd.Title;
    ad.Description = inputAd.Description;
    ad.Phone = inputAd.Phone;

    await db.SaveChangesAsync();

    return Results.NoContent();
});

// Delete an ad
app.MapDelete("/ads/{id}", async (int id, AdsContext db) =>
{
    if (await db.Ads.FindAsync(id) is Ad ad)
    {
        db.Ads.Remove(ad);
        await db.SaveChangesAsync();
        return Results.Ok(ad);
    }

    return Results.NotFound();
});

app.Run();