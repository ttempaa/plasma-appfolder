<p align="center">
  <img src="docs/icon.png" width="84" alt="Папка приложений" />
</p>

<h1 align="center">Папка приложений</h1>

<p align="center">
  Папка с приложениями на рабочем столе Plasma.
  Виджет собирает живую иконку из содержимого папки и по клику открывает popup с ярлыками.
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="Лицензия: MIT" /></a>
  <img src="https://img.shields.io/badge/Plasma-6-1d99f3" alt="KDE Plasma 6" />
  <img src="https://img.shields.io/badge/lang-ru%20%7C%20en-inactive" alt="Интерфейс: русский и английский" />
</p>

<p align="center">
  <a href="README.md">English</a> | Русский
</p>

<p align="center">
  <img width="675" height="450" alt="demo.webp" src="https://github.com/user-attachments/assets/ee0d1ff6-b962-4dfd-b18d-59a13fac47d3" />
</p>

## Возможности

- **Живая иконка** — собирается из иконок приложений в папке, содержимое видно ещё до открытия
- **Ноль настройки** — новому виджету папка создаётся сама, можно сразу тащить ярлыки
- **Всё перетаскиванием** — бросьте `.desktop` на виджет, потяните иконку из popup наружу; файл просто переезжает
- **Обычная папка** — просто `.desktop`-файлы: правьте хоть в Dolphin, хоть из терминала, синхронизируйте как угодно — изменения подхватываются сами
- **Умный popup** — сам выбирает сторону экрана и не лезет за края; сортировка, прокрутка, клик или наведение

## Установка

### Из магазина

Правый клик по рабочему столу → «Добавить виджеты…» → «Загрузить новые виджеты…», поиск «App Folder».

### Из релизов

Скачайте `plasma-appfolder.plasmoid` со [страницы релизов](https://github.com/ttempaa/plasma-appfolder/releases):

```sh
kpackagetool6 --type Plasma/Applet --install plasma-appfolder.plasmoid
```

### Из исходников

Нужны `make` и `msgfmt` (пакет gettext):

```sh
git clone https://github.com/ttempaa/plasma-appfolder
cd plasma-appfolder
make && kpackagetool6 --type Plasma/Applet --install .
```

Обновление — `--upgrade` вместо `--install`; удаление — `--remove com.github.ttempaa.plasma.appfolder`.
Данные виджетов (папки и общий конфиг) живут в `~/.local/share/plasma-appfolder/`.

## Совместимость

Plasma 6 (разработка и тесты — 6.8, Wayland).

## Лицензия

Код — [MIT](LICENSE). Глифы иконки — [Lucide](https://lucide.dev), лицензия ISC.
