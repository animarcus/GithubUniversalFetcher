function run(arguments) {
    var app = Application.currentApplication();
    app.includeStandardAdditions = true;
    var thePath = arguments[0];
    const giveUpDelay = 8;

    var userChoice = app.displayDialog(
        "Download located at " +
            thePath +
            "\nWould you like to open the location in Finder?",
        {
            buttons: ["No", "Yes"],
            defaultButton: "Yes",
            cancelButton: "No",
            withTitle: "📥 Github Universal Fetcher",
            givingUpAfter: giveUpDelay,
        }
    );

    if (userChoice.buttonReturned == "Yes") {
        var finder = Application("Finder");
        finder.activate();
        finder.open(thePath);
    }
}
