function getVisibleFinderDirectory() {
    var systemEvents = Application("System Events");
    var finder = Application("Finder");
    var finderIsVisible =
        systemEvents.processes.whose({ visible: true, name: "Finder" }).length >
        0;

    if (finderIsVisible) {
        finder.activate();
        if (finder.windows.length > 0) {
            var frontWindow = finder.windows[0];
            var desktopBounds = finder.desktop.window.bounds();
            var windowBounds = frontWindow.bounds();

            var halfWidth = desktopBounds.width / 2;
            var halfHeight = desktopBounds.height / 2;
            var windowWidth = windowBounds.width;
            var windowHeight = windowBounds.height;

            frontWindow.bounds = {
                x: halfWidth - windowWidth / 2,
                y: halfHeight - windowHeight / 2,
                width: halfWidth + windowWidth / 2,
                height: halfHeight + windowHeight / 2,
            };

            return frontWindow.target().toString();
        }
    }
    return Path("~/Downloads").toString();
}

// console.log(getVisibleFinderDirectory());
