using System.Security.Principal;
using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .AddTransforms(transforms =>
    {
        transforms.AddRequestTransform(context =>
        {
            // Remove any client-supplied spoofed header
            context.ProxyRequest.Headers.Remove("X-Remote-User");

            // IIS Windows Auth user
            var name = context.HttpContext.User?.Identity?.Name; // "DOMAIN\\user"
            if (!string.IsNullOrWhiteSpace(name))
            {
                context.ProxyRequest.Headers.Add("X-Remote-User", name);
            }

            return ValueTask.CompletedTask;
        });
    });

var app = builder.Build();

app.MapReverseProxy();
app.Run();
