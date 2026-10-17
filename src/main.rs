mod store;
mod window;

use adw::prelude::*;
use gtk::{gio, glib};

const APP_ID: &str = "io.github.crian.GWeatherAddLoc";

#[allow(deprecated)]
fn show_about(app: &adw::Application) {
    let about = adw::AboutWindow::builder()
        .application_name("Weather Locations")
        .application_icon(APP_ID)
        .version(env!("CARGO_PKG_VERSION"))
        .comments("Add custom locations with arbitrary coordinates to GNOME Weather.")
        .website("https://github.com/crian/gweather-add-loc")
        .license_type(gtk::License::MitX11)
        .build();
    about.set_transient_for(app.active_window().as_ref());
    about.present();
}

fn main() -> glib::ExitCode {
    let app = adw::Application::builder().application_id(APP_ID).build();

    app.connect_startup(|app| {
        let quit = gio::ActionEntry::builder("quit")
            .activate(|app: &adw::Application, _, _| app.quit())
            .build();
        let about = gio::ActionEntry::builder("about")
            .activate(|app: &adw::Application, _, _| show_about(app))
            .build();
        app.add_action_entries([quit, about]);
        app.set_accels_for_action("app.quit", &["<primary>q"]);
        app.set_accels_for_action("win.reload", &["<primary>r"]);
    });

    app.connect_activate(|app| {
        if let Some(win) = app.active_window() {
            win.present();
        } else {
            window::build(app).present();
        }
    });

    app.run()
}
