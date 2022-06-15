// SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QFuture>
#include <QFutureWatcher>
#include <QPointer>
#include <QtConcurrent/QtConcurrentRun>

template<typename T>
void asyncRun(QObject *object, std::function<T()> run, std::function<void(T)> continuation)
{
    auto guard = QPointer<QObject>{object};
    auto future = QtConcurrent::run(run);
    auto watcher = new QFutureWatcher<T>;
    QObject::connect(watcher, &QFutureWatcher<T>::finished, watcher, [watcher, continuation, guard]() {
        if (guard) {
            continuation(watcher->future().result());
        }
        delete watcher;
    });
    watcher->setFuture(future);
}
