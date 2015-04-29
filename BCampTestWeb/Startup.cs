using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(BCampTestWeb.Startup))]
namespace BCampTestWeb
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
