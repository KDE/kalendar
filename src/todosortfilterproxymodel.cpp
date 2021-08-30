// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <KConfigWatcher>
#include <todosortfilterproxymodel.h>

class ExtraTodoModel : public KExtraColumnsProxyModel
{
    Q_OBJECT

public:
    enum Columns {
        StartTimeColumn = 0,
        EndTimeColumn,
        PriorityIntColumn
    };
    Q_ENUM(Columns);
    enum Roles { // Remember to update roles in todosortfilterproxymodel
        StartTimeRole = TodoModel::CalendarRole + 1,
        EndTimeRole,
        LocationRole,
        AllDayRole,
        CompletedRole,
        PriorityRole,
        ColorRole,
        CollectionIdRole,
        DurationStringRole,
        RecursRole,
        IsOverdueRole,
        IncidenceIdRole,
        IncidenceTypeRole,
        IncidenceTypeStrRole,
        IncidenceTypeIconRole,
        IncidencePtrRole,
        TreeDepthRole
    };
    Q_ENUM(Roles);

    ExtraTodoModel(QObject *parent = nullptr) : KExtraColumnsProxyModel(parent) {
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
    };
    ~ExtraTodoModel() = default;

    QVariant extraColumnData(const QModelIndex &parent, int row, int extraColumn, int role = Qt::DisplayRole) const override {
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
    };

    QVariant data (const QModelIndex &index, int  role = Qt::DisplayRole) const override {
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
    };

    QHash<int, QByteArray> roleNames() const override {
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
        roleNames[Roles::TreeDepthRole] = "treeDepth";

        return roleNames;
    }

    Akonadi::ETMCalendar::Ptr calendar() {
        return m_calendar;
    }

    void setCalendar(Akonadi::ETMCalendar::Ptr calendar) {
        m_calendar = calendar;
        m_todoTreeModel->setSourceModel(calendar->model());
        m_baseTodoModel->setCalendar(calendar);
    };

    void setIncidenceChanger(Akonadi::IncidenceChanger* changer) {
        m_baseTodoModel->setIncidenceChanger(changer);
    };

    QHash<QString, QColor> colorCache() {
        return m_colors;
    };

    void setColorCache(QHash<QString, QColor> colorCache) {
        m_colors = colorCache;
    };

    void loadColors() {
        KSharedConfig::Ptr config = KSharedConfig::openConfig();
        KConfigGroup rColorsConfig(config, "Resources Colors");
        const QStringList colorKeyList = rColorsConfig.keyList();

        for (const QString &key : colorKeyList) {
            QColor color = rColorsConfig.readEntry(key, QColor("blue"));
            m_colors[key] = color;
        }
        Q_EMIT layoutChanged();
    }

private:
    Akonadi::ETMCalendar::Ptr m_calendar;
    IncidenceTreeModel *m_todoTreeModel = nullptr;
    TodoModel *m_baseTodoModel = nullptr;
    QHash<QString, QColor> m_colors;
    KConfigWatcher::Ptr m_colorWatcher;
};





TodoSortFilterProxyModel::TodoSortFilterProxyModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    m_extraTodoModel = new ExtraTodoModel;
    setSourceModel(m_extraTodoModel);
    setDynamicSortFilter(true);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

bool TodoSortFilterProxyModel::filterAcceptsRow(int row, const QModelIndex &sourceParent) const
{
    if(filterAcceptsRowCheck(row, sourceParent)) {
        return true;
    }

    // Accept if any parent is accepted itself
    QModelIndex parent = sourceParent;
    while (parent.isValid()) {
        if (filterAcceptsRowCheck(parent.row(), parent.parent()))
            return true;
        parent = parent.parent();
    }

    // Accept if any child is accepted itself
    if (hasAcceptedChildren(row, sourceParent)) {
        return true;
    }

    return false;
}

bool TodoSortFilterProxyModel::filterAcceptsRowCheck(int row, const QModelIndex& sourceParent) const
{
    const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
    Q_ASSERT(sourceIndex.isValid());

    bool acceptRow = true;

    if(m_filterCollectionId > -1) {
        acceptRow = acceptRow && sourceIndex.data(ExtraTodoModel::CollectionIdRole).toInt() == m_filterCollectionId;
    }

    switch(m_showCompleted) {
        case ShowComplete::ShowCompleteOnly:
            acceptRow = acceptRow && sourceIndex.data(ExtraTodoModel::CompletedRole).toBool();
            break;
        case ShowComplete::ShowIncompleteOnly:
            acceptRow = acceptRow && !sourceIndex.data(ExtraTodoModel::CompletedRole).toBool();
        case ShowComplete::ShowAll:
        default:
            break;
    }

    return acceptRow ? QSortFilterProxyModel::filterAcceptsRow(row, sourceParent) : acceptRow;
}

bool TodoSortFilterProxyModel::hasAcceptedChildren(int row, const QModelIndex& sourceParent) const
{
    QModelIndex index = sourceModel()->index(row, 0, sourceParent);
    if (!index.isValid()) {
        return false;
    }

    int childCount = index.model()->rowCount(index);
    if (childCount == 0)
        return false;

    for (int i = 0; i < childCount; ++i) {
        if (filterAcceptsRowCheck(i, index))
            return true;

        if (hasAcceptedChildren(i, index))
            return true;
    }

    return false;
}

void TodoSortFilterProxyModel::setCalendar(Akonadi::ETMCalendar *calendar)
{
    Akonadi::ETMCalendar::Ptr calendarPtr(calendar);
    m_extraTodoModel->setCalendar(calendarPtr);
    Q_EMIT calendarChanged();
}

void TodoSortFilterProxyModel::setIncidenceChanger(Akonadi::IncidenceChanger* changer)
{
    m_extraTodoModel->setIncidenceChanger(changer);
    Q_EMIT incidenceChangerChanged();
}

void TodoSortFilterProxyModel::setColorCache(QHash<QString, QColor> colorCache)
{
    m_extraTodoModel->setColorCache(colorCache);
}

qint64 TodoSortFilterProxyModel::filterCollectionId()
{
    return m_filterCollectionId;
}

void TodoSortFilterProxyModel::setFilterCollectionId(qint64 filterCollectionId)
{
    Q_EMIT layoutAboutToBeChanged();
    m_filterCollectionId = filterCollectionId;
    invalidateFilter();
    Q_EMIT filterCollectionIdChanged();
    Q_EMIT layoutChanged();
}

int TodoSortFilterProxyModel::showCompleted()
{
    return m_showCompleted;
}

void TodoSortFilterProxyModel::setShowCompleted(int showCompleted)
{
    m_showCompleted = showCompleted;
    m_showCompletedStore = showCompleted; // For when we search
    invalidateFilter();
    Q_EMIT showCompletedChanged();
}

void TodoSortFilterProxyModel::sortTodoModel(int column, bool ascending)
{
    auto order = ascending ? Qt::AscendingOrder : Qt::DescendingOrder;
    this->sort(column, order);
}

void TodoSortFilterProxyModel::filterTodoName(QString name, int showCompleted)
{
    Q_EMIT layoutAboutToBeChanged();
    setFilterFixedString(name);
    if(name.length() > 0) {
        m_showCompleted = showCompleted;
    } else {
        setShowCompleted(m_showCompletedStore);
    }
    invalidateFilter();
    Q_EMIT layoutChanged();
}


Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
#include "todosortfilterproxymodel.moc"

