// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <extratodomodel.h>

ExtraTodoModel::ExtraTodoModel(QObject *parent)
: KExtraColumnsProxyModel(parent) {
    const QString todoMimeType = QStringLiteral("application/x-vnd.akonadi.calendar.todo");
    m_todoTreeModel = new IncidenceTreeModel(QStringList() << todoMimeType, this);
    const auto pref = EventViews::PrefsPtr();
    m_baseTodoModel = new TodoModel(pref, this);
    m_baseTodoModel->setSourceModel(m_todoTreeModel);
    setSourceModel(m_baseTodoModel);

    appendColumn(QLatin1String("StartDateTime"));
    appendColumn(QLatin1String("EndDateTime"));
    appendColumn(QLatin1String("PriorityInt"));

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    m_colorWatcher = KConfigWatcher::create(config);

    QObject::connect(m_colorWatcher.data(), &KConfigWatcher::configChanged, this, &ExtraTodoModel::loadColors);

    loadColors();
}

QVariant ExtraTodoModel::extraColumnData(const QModelIndex &parent, int row, int extraColumn, int role) const {
    if (role != Qt::DisplayRole && role != Qt::EditRole) {
        return QVariant();
    }

    const auto todoItem = index(row, extraColumn, parent).data(TodoModel::TodoRole).value<Akonadi::Item>();
    const auto todoPtr = CalendarSupport::todo(todoItem);

    switch (extraColumn) {
        case StartTimeColumn:
            return todoPtr->dtStart();
        case EndTimeColumn:
            return todoPtr->dtDue();
        case PriorityIntColumn:
            return todoPtr->priority();
        default:
            return QVariant();
    }
}

QVariant ExtraTodoModel::data (const QModelIndex &index, int role) const {
    if (!index.isValid()) {
        return QVariant();
    }

    auto idx = mapToSource(index);
    auto todoItem = idx.data(TodoModel::TodoRole).value<Akonadi::Item>();
    auto collectionId = todoItem.parentCollection().id();
    auto todoPtr = CalendarSupport::todo(todoItem);

    if(role == Roles::StartTimeRole) {
        return todoPtr->dtStart();
    } else if (role == Roles::EndTimeRole) {
        return todoPtr->dtDue();
    } else if(role == Roles::LocationRole) {
        return todoPtr->location();
    } else if(role == Roles::AllDayRole) {
        return todoPtr->allDay();
    } else if(role == Roles::ColorRole) {
        QColor nullcolor;
        return m_colors.contains(QString::number(collectionId)) ? m_colors[QString::number(collectionId)] : nullcolor;
    } else if(role == Roles::CompletedRole) {
        return todoPtr->isCompleted();
    } else if(role == Roles::PriorityRole) {
        return todoPtr->priority();
    } else if(role == Roles::CollectionIdRole) {
        return collectionId;
    } else if (role == DurationStringRole) {
        KFormat format;
        if (todoPtr->allDay()) {
            return format.formatSpelloutDuration(24*60*60*1000); // format milliseconds in 1 day
        }
        return format.formatSpelloutDuration(todoPtr->duration().asSeconds() * 1000);
    } else if (role == Roles::RecursRole) {
        return todoPtr->recurs();
    } else if (role == Roles::IsOverdueRole) {
        return todoPtr->isOverdue();
    } else if(role == Roles::IncidenceIdRole) {
        return todoPtr->uid();
    } else if(role == Roles::IncidenceTypeRole) {
        return todoPtr->type();
    } else if(role == Roles::IncidenceTypeStrRole) {
        return todoPtr->typeStr();
    } else if(role == Roles::IncidenceTypeIconRole) {
        return todoPtr->iconName();
    } else if(role == Roles::IncidencePtrRole) {
        return QVariant::fromValue(CalendarSupport::incidence(todoItem));
    } else if(role == Roles::TagsRole) {
        return QVariant::fromValue(todoItem.tags());
    } else if(role == Roles::ItemRole) {
        return QVariant::fromValue(todoItem);
    } else if(role == Roles::CategoriesRole) {
        return todoPtr->categories();
    } else if(role == Roles::CategoriesDisplayRole) {
        return todoPtr->categories().join(i18nc("List separator", ", "));
    } else if(role == Roles::TreeDepthRole) {
        int depth = 0;
        auto idx = index;
        while(idx.parent().isValid()) {
            idx = idx.parent();
            depth++;
        }
        return depth;
    }

    return KExtraColumnsProxyModel::data(index, role);
}

QHash<int, QByteArray> ExtraTodoModel::roleNames() const {
    QHash<int, QByteArray> roleNames = KExtraColumnsProxyModel::roleNames();
    roleNames[TodoModel::SummaryRole] = "text";
    roleNames[Roles::StartTimeRole] = "startTime";
    roleNames[Roles::EndTimeRole] = "endTime";
    roleNames[Roles::LocationRole] = "location";
    roleNames[Roles::AllDayRole] = "allDay";
    roleNames[Roles::ColorRole] = "color";
    roleNames[Roles::CompletedRole] = "todoCompleted";
    roleNames[Roles::PriorityRole] = "priority";
    roleNames[Roles::CollectionIdRole] = "collectionId";
    roleNames[Roles::DurationStringRole] = "durationString";
    roleNames[Roles::RecursRole] = "recurs";
    roleNames[Roles::IsOverdueRole] = "isOverdue";
    roleNames[Roles::IncidenceIdRole] = "incidenceId";
    roleNames[Roles::IncidenceTypeRole] = "incidenceType";
    roleNames[Roles::IncidenceTypeStrRole] = "incidenceTypeStr";
    roleNames[Roles::IncidenceTypeIconRole] = "incidenceTypeIcon";
    roleNames[Roles::IncidencePtrRole] = "incidencePtr";
    roleNames[Roles::TagsRole] = "tags";
    roleNames[Roles::ItemRole] = "item";
    roleNames[Roles::CategoriesRole] = "categories";
    roleNames[Roles::CategoriesDisplayRole] = "categoriesDisplay";
    roleNames[Roles::TreeDepthRole] = "treeDepth";

    return roleNames;
}

Akonadi::ETMCalendar::Ptr ExtraTodoModel::calendar() {
    return m_calendar;
}

void ExtraTodoModel::setCalendar(Akonadi::ETMCalendar::Ptr calendar) {
    m_calendar = calendar;
    m_todoTreeModel->setSourceModel(calendar->model());
    m_baseTodoModel->setCalendar(calendar);
}

void ExtraTodoModel::setIncidenceChanger(Akonadi::IncidenceChanger* changer) {
    m_baseTodoModel->setIncidenceChanger(changer);
}

QHash<QString, QColor> ExtraTodoModel::colorCache() {
    return m_colors;
}

void ExtraTodoModel::setColorCache(QHash<QString, QColor> colorCache) {
    m_colors = colorCache;
}

void ExtraTodoModel::loadColors() {
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    const QStringList colorKeyList = rColorsConfig.keyList();

    for (const QString &key : colorKeyList) {
        QColor color = rColorsConfig.readEntry(key, QColor("blue"));
        m_colors[key] = color;
    }
    Q_EMIT layoutChanged();
}

Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
