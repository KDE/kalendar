// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KontactInterface/Plugin>

class OrgKdeKalendarPartInterface;

namespace KontactInterface
{
class UniqueAppWatcher;
}

class KalendarPlugin : public KontactInterface::Plugin
{
    Q_OBJECT

public:
    KalendarPlugin(KontactInterface::Core *core, const QVariantList &);
    ~KalendarPlugin() override;

    Q_REQUIRED_RESULT bool isRunningStandalone() const override;
    int weight() const override
    {
        return 400;
    }

    Q_REQUIRED_RESULT QStringList invisibleToolbarActions() const override;

    OrgKdeKalendarPartInterface *interface();

protected:
    KParts::Part *createPart() override;

private:
    OrgKdeKalendarPartInterface *mIface = nullptr;
    KontactInterface::UniqueAppWatcher *mUniqueAppWatcher = nullptr;
};
