// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later
#include "about.h"
#include "akonadi/collectionfilterproxymodel.h"
#include "config-kalendar.h"
#include "kalendarapplication.h"
#include "kalendarconfig.h"
#include <Akonadi/AgentFilterProxyModel>
#include <KAboutData>
#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KWindowConfig>
#include <KWindowSystem>
#include <QApplication>
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDir>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QUrl>

using namespace KCalendarCore;

static void raiseWindow(QWindow *window)
{
    KWindowSystem::updateStartupId(window);
    KWindowSystem::activateWindow(window);
}

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("kalendar");
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setApplicationName(QStringLiteral("Kalendar"));

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

#if defined(Q_OS_WIN) || defined(Q_OS_MAC)
    QApplication::setStyle(QStringLiteral("breeze"));
#endif

    KAboutData aboutData(
        // The program name used internally.
        QStringLiteral("kalendar"),
        // A displayable program name string.
        i18nc("@title", "Kalendar"),
        QStringLiteral(KALENDAR_VERSION_STRING),
        // Short description of what the app does.
        i18n("Calendar Application"),
        // The license this code is released under.
        KAboutLicense::GPL_V3,
        // Copyright Statement.
        i18n("(c) KDE Community 2021"));
    aboutData.addAuthor(i18nc("@info:credit", "Carl Schwan"),
                        i18nc("@info:credit", "Maintainer"),
                        QStringLiteral("carl@carlschwan.eu"),
                        QStringLiteral("https://carlschwan.eu"));
    aboutData.addAuthor(i18nc("@info:credit", "Clau Cambra"),
                        i18nc("@info:credit", "Maintainer"),
                        QStringLiteral("claudio.cambra@gmail.com"),
                        QStringLiteral("https://claudiocambra.com"));
    aboutData.addAuthor(i18nc("@info:credit", "Felipe Kinoshita"),
                        i18nc("@info:credit", "Developer"),
                        QStringLiteral("kinofhek@gmail.com"),
                        QStringLiteral("https://fhek.gitlab.io"));
    KAboutData::setApplicationData(aboutData);
    QGuiApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("org.kde.kalendar")));

    QCommandLineParser parser;
    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    auto config = KalendarConfig::self();
    auto kalendarApplication = new KalendarApplication;

    KDBusService service(KDBusService::Unique);
    service.connect(&service,
                    &KDBusService::activateRequested,
                    kalendarApplication,
                    [kalendarApplication, &parser](const QStringList &arguments, const QString &workingDirectory) {
                        parser.parse(arguments);
                        const QStringList args = parser.positionalArguments();
                        for (const auto &arg : args) {
                            Q_EMIT kalendarApplication->importCalendarFromFile(QUrl::fromUserInput(arg, workingDirectory, QUrl::AssumeLocalFile));
                        }
                    });

    QQmlApplicationEngine engine;

    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "Config", config);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "AboutType", new AboutType());
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "KalendarApplication", kalendarApplication);

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.load(QUrl(QStringLiteral("qrc:///main.qml")));

    qRegisterMetaType<QAbstractProxyModel *>("QAbstractProxyModel*");
    qRegisterMetaType<QAction *>();

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    QObject::connect(&service, &KDBusService::activateRequested, &engine, [&engine](const QStringList & /*arguments*/, const QString & /*workingDirectory*/) {
        const auto rootObjects = engine.rootObjects();
        for (auto obj : rootObjects) {
            auto view = qobject_cast<QQuickWindow *>(obj);
            if (view) {
                raiseWindow(view);
                return;
            }
        }
    });
    const auto rootObjects = engine.rootObjects();
    for (auto obj : rootObjects) {
        auto view = qobject_cast<QQuickWindow *>(obj);
        if (view) {
            KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
            KConfigGroup windowGroup(&dataResource, "Window");
            KWindowConfig::restoreWindowSize(view, windowGroup);
            KWindowConfig::restoreWindowPosition(view, windowGroup);
            break;
        }
    }

    if (!parser.positionalArguments().empty()) {
        const auto args = parser.positionalArguments();
        for (const auto &arg : args) {
            Q_EMIT kalendarApplication->importCalendarFromFile(QUrl::fromUserInput(arg, QDir::currentPath(), QUrl::AssumeLocalFile));
        }
    }

    QDBusConnection::sessionBus().interface()->startService(QStringLiteral("org.kde.kalendarac"));

    return app.exec();
}
