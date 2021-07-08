# Kalendar

Kalendar is a Kirigami-based calendar application that uses Akonadi. It lets you add, edit and delete events from local and remote accounts of your choice, while keeping changes syncronised across your Plasma desktop or phone.

Kalendar is still under heavy development, but welcomes suggestions!

## Screenshots

![Screenshot of Kalendar](screenshot.png)

## Build

```
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=~/.local/kde -GNinja
ninja
```

## License

This project is licensed under LGPL-2.1-or-later. Some files are licensed under
more permissive licenses.
