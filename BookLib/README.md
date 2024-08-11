#  About BookLib

## Intended User Experience

* This app is intended to organize notes and themes for a user's list of books.

* When a user opens the app, they should see a tabbed view, with three screens: the Search View, the Barcode Scanner view, and the Reading List view. 

* The default screen—the Search View—allows them to search for books of their interest, and add them to their reading list. This search is done using the Google Books API. Each SearchQuery is stored in UserDefaults.
   * There is an advanced search grey widget at the top, which allows the user to specify specific parameters like the title, author, publisher, or ISBN number.
   * When the user taps on the information button, they can see more details about a book. The plus button next to it allows the user to add the book; if the book is already in the reading list, there is a checkmark instead.

* The second screen in the tabbed view allows a user to use a book's barcode to scan it into their reading list. There are two buttons—a camera and photo album button—to upload an image containing the book's ISBN barcode. After selecting an image (either by taking a photo, or picking from the photo album), a new screen appears. This screen lists all the barcodes detected in the image, but also allows the user to enter a custom ISBN. The VC also validates the custom ISBN, if it is entered.
  *   After the ISBN is entered, the app switches to a search screen and displays books with that particular ISBN. Just as the default screen, the user can also add these books to their reading list.

* The third screen stores the user's current reading list.
    * When the user taps on any book in the current reading list, they can see three widgets in the next screen: one to view the book's information, one to view the book's themes, and one to view all of this book's notes.
    * The user can swipe down or up on the theme's widgets to view more of the book's themes.
        * When the user taps a particular theme, they can view a list of notes related to a theme.
        * There is a "+" sign on the themes widget to create a new theme.
    * The user can tap on the third widget to see a list of ALL of the notes and folders (which are not placed in a folder) related to this book.

* When the user views a list of notes, they can tap on a particular note to edit or view its contents.
    * There is a collection view at the top that has a "+" icon at the top, enabling the user to add themes.
        * A new screen pops up that allows the user to add themes to the note by clicking the corresponding "+" button. The user can also create new themes in the text field at the top.
    * There is also a table view in the note editing screen, where the user can add content to the note.
        * The user can add content by scanning or typing a note.
        * The user can swipe to delete items.
        * If the user taps a scanned note, they see a detail view, where they can view the image closer up and change it if needed.

## Running the project

* Due to the barcode scanner, this app relies on three Firebase API libraries: GoogleMLKit, MLModelDownloader, and BarcodeScanning.
* When this project is downloaded, also make sure CocoaPods is installed.
    * If Ruby is installed on your Mac, you can use the Ruby `gem` package manager, as shown below, to install CocoaPods.
`sudo gem install cocoapods`
    * Otherwise, Homebrew may also work.
`brew install cocoapods`
    * Instructions are available on the CocoaPods site here: https://cocoapods.org/.
* Once CocoaPods is installed, run the following command in the project directory:
`pod install`
    * This command should install the Firebase libraries.
    * After this command is run, open the .xcworkspace file generated.
    * The xcworkspace should build.

