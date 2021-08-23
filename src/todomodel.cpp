/*
  SPDX-FileCopyrightText: 2008 Thomas Thrainer <tom_t@gmx.at>
  SPDX-FileCopyrightText: 2012 Sérgio Martins <iamsergio@gmail.com>

  SPDX-License-Identifier: GPL-2.0-or-later WITH Qt-Commercial-exception-1.0
*/

#include "incidencetreemodel.h"
#include "todomodel_p.h"

#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <KCalUtils/IncidenceFormatter>
#include <KCalendarCore/Attachment>
#include <KCalendarCore/Event>
#include <KEmailAddress>
#include <KLocalizedString>

#include <KCalUtils/DndFactory>
#include <KCalUtils/ICalDrag>
#include <KCalUtils/VCalDrag>

//#include "calendarview_debug.h"
#include <KMessageBox>

#include <QIcon>
#include <QMimeData>

struct SourceModelIndex {
    SourceModelIndex(int _r, int _c, void *_p, QAbstractItemModel *_m)
        : r(_r)
        , c(_c)
        , p(_p)
        , m(_m)
    {
    }

    operator QModelIndex()
    {
        return reinterpret_cast<QModelIndex &>(*this);
    }

    int r, c;
    void *p;
    const QAbstractItemModel *m = nullptr;
};

static bool isDueToday(const KCalendarCore::Todo::Ptr &todo)
{
    return !todo->isCompleted() && todo->dtDue().date() == QDate::currentDate();
}

TodoModel::Private::Private(const EventViews::PrefsPtr &preferences, TodoModel *qq)
    : QObject()
    , m_preferences(preferences)
    , q(qq)
{
}

Akonadi::Item TodoModel::Private::findItemByUid(const QString &uid, const QModelIndex &parent) const
{
    Q_ASSERT(!uid.isEmpty());
    auto treeModel = qobject_cast<IncidenceTreeModel *>(q->sourceModel());
    if (treeModel) { // O(1) Shortcut
        return treeModel->item(uid);
    }

    Akonadi::Item item;
    const int count = q->rowCount(parent);
    for (int i = 0; i < count; ++i) {
        const QModelIndex currentIndex = q->index(i, 0, parent);
        Q_ASSERT(currentIndex.isValid());
        item = q->data(currentIndex, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (item.isValid()) {
            return item;
        } else {
            item = findItemByUid(uid, currentIndex);
            if (item.isValid()) {
                return item;
            }
        }
    }

    return item;
}

void TodoModel::Private::onDataChanged(const QModelIndex &begin, const QModelIndex &end)
{
    Q_ASSERT(begin.isValid());
    Q_ASSERT(end.isValid());
    const QModelIndex proxyBegin = q->mapFromSource(begin);
    Q_ASSERT(proxyBegin.column() == 0);
    const QModelIndex proxyEnd = q->mapFromSource(end);
    Q_EMIT q->dataChanged(proxyBegin, proxyEnd.sibling(proxyEnd.row(), TodoModel::ColumnCount - 1));
}

void TodoModel::Private::onHeaderDataChanged(Qt::Orientation orientation, int first, int last)
{
    Q_EMIT q->headerDataChanged(orientation, first, last);
}

void TodoModel::Private::onRowsAboutToBeInserted(const QModelIndex &parent, int begin, int end)
{
    const QModelIndex index = q->mapFromSource(parent);
    Q_ASSERT(!(parent.isValid() ^ index.isValid())); // Both must be valid, or both invalid
    Q_ASSERT(!(index.isValid() && index.model() != q));

    q->beginInsertRows(index, begin, end);
}

void TodoModel::Private::onRowsInserted(const QModelIndex &, int, int)
{
    q->endInsertRows();
}

void TodoModel::Private::onRowsAboutToBeRemoved(const QModelIndex &parent, int begin, int end)
{
    const QModelIndex index = q->mapFromSource(parent);
    Q_ASSERT(!(parent.isValid() ^ index.isValid())); // Both must be valid, or both invalid
    Q_ASSERT(!(index.isValid() && index.model() != q));

    q->beginRemoveRows(index, begin, end);
}

void TodoModel::Private::onRowsRemoved(const QModelIndex &, int, int)
{
    q->endRemoveRows();
}

void TodoModel::Private::onRowsAboutToBeMoved(const QModelIndex &sourceParent,
                                              int sourceStart,
                                              int sourceEnd,
                                              const QModelIndex &destinationParent,
                                              int destinationRow)
{
    Q_UNUSED(sourceParent)
    Q_UNUSED(sourceStart)
    Q_UNUSED(sourceEnd)
    Q_UNUSED(destinationParent)
    Q_UNUSED(destinationRow)
    /* Disabled for now, layoutAboutToBeChanged() is emitted
    q->beginMoveRows( q->mapFromSource( sourceParent ), sourceStart, sourceEnd,
                      q->mapFromSource( destinationParent ), destinationRow );
    */
}

void TodoModel::Private::onRowsMoved(const QModelIndex &, int, int, const QModelIndex &, int)
{
    /*q->endMoveRows();*/
}

void TodoModel::Private::onModelAboutToBeReset()
{
    q->beginResetModel();
}

void TodoModel::Private::onModelReset()
{
    q->endResetModel();
}

void TodoModel::Private::onLayoutAboutToBeChanged()
{
    Q_ASSERT(m_persistentIndexes.isEmpty());
    Q_ASSERT(m_layoutChangePersistentIndexes.isEmpty());
    Q_ASSERT(m_columns.isEmpty());
    const QModelIndexList persistentIndexes = q->persistentIndexList();
    for (const QPersistentModelIndex &persistentIndex : persistentIndexes) {
        m_persistentIndexes << persistentIndex; // Stuff we have to update onLayoutChanged
        Q_ASSERT(persistentIndex.isValid());
        QModelIndex index_col0 = q->createIndex(persistentIndex.row(), 0, persistentIndex.internalPointer());
        const QPersistentModelIndex srcPersistentIndex = q->mapToSource(index_col0);
        Q_ASSERT(srcPersistentIndex.isValid());
        m_layoutChangePersistentIndexes << srcPersistentIndex;
        m_columns << persistentIndex.column();
    }
    Q_EMIT q->layoutAboutToBeChanged();
}

void TodoModel::Private::onLayoutChanged()
{
    for (int i = 0; i < m_persistentIndexes.size(); ++i) {
        QModelIndex newIndex_col0 = q->mapFromSource(m_layoutChangePersistentIndexes.at(i));
        Q_ASSERT(newIndex_col0.isValid());
        const int column = m_columns.at(i);
        QModelIndex newIndex = column == 0 ? newIndex_col0 : q->createIndex(newIndex_col0.row(), column, newIndex_col0.internalPointer());
        q->changePersistentIndex(m_persistentIndexes.at(i), newIndex);
    }

    m_layoutChangePersistentIndexes.clear();
    m_persistentIndexes.clear();
    m_columns.clear();
    Q_EMIT q->layoutChanged();
}

TodoModel::TodoModel(const EventViews::PrefsPtr &preferences, QObject *parent)
    : QAbstractProxyModel(parent)
    , d(new Private(preferences, this))
{
    setObjectName(QStringLiteral("TodoModel"));
}

TodoModel::~TodoModel()
{
    delete d;
}

QVariant TodoModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(index.isValid());
    if (!index.isValid() || !d->m_calendar) {
        return QVariant();
    }

    const QModelIndex sourceIndex = mapToSource(index.sibling(index.row(), 0));
    if (!sourceIndex.isValid()) {
        return QVariant();
    }
    Q_ASSERT(sourceIndex.isValid());
    const auto item = sourceIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    if (!item.isValid()) {
        //qCWarning(CALENDARVIEW_LOG) << "Invalid index: " << sourceIndex;
        // Q_ASSERT( false );
        return QVariant();
    }
    const KCalendarCore::Todo::Ptr todo = CalendarSupport::todo(item);
    if (!todo) {
        //qCCritical(CALENDARVIEW_LOG) << "item.hasPayload()" << item.hasPayload();
        if (item.hasPayload<KCalendarCore::Incidence::Ptr>()) {
            auto incidence = item.payload<KCalendarCore::Incidence::Ptr>();
            if (incidence) {
                //qCCritical(CALENDARVIEW_LOG) << "It's actually " << incidence->type();
            }
        }

        Q_ASSERT(!"There's no to-do.");
        return QVariant();
    }

    switch (role) {
    case SummaryRole:
        return todo->summary();
    case RecurRole:
        if (todo->recurs()) {
            if (todo->hasRecurrenceId()) {
                return i18nc("yes, an exception to a recurring to-do", "Exception");
            } else {
                return i18nc("yes, recurring to-do", "Yes");
            }
        } else {
            return i18nc("no, not a recurring to-do", "No");
        }
    case PriorityRole:
        if (todo->priority() == 0) {
            return QStringLiteral("--");
        }
        return todo->priority();
    case PercentRole:
        return todo->percentComplete();
    case StartDateRole:
        return todo->hasStartDate() ? QLocale().toString(todo->dtStart().toLocalTime().date(), QLocale::ShortFormat) : QString();
    case DueDateRole:
        return todo->hasDueDate() ? QLocale().toString(todo->dtDue().toLocalTime().date(), QLocale::ShortFormat) : QString();
    case CategoriesRole: {
        return todo->categories().join(i18nc("delimiter for joining category/tag names", ","));
    }
    case DescriptionRole:
        return todo->description();
    case CalendarRole:
        return CalendarSupport::displayName(d->m_calendar.data(), item.parentCollection());
    default:
        break; // column based model handling
    }

    if (role == Qt::DisplayRole) {
        switch (index.column()) {
        case SummaryColumn:
            return QVariant(todo->summary());
        case RecurColumn:
            if (todo->recurs()) {
                if (todo->hasRecurrenceId()) {
                    return i18nc("yes, an exception to a recurring to-do", "Exception");
                } else {
                    return i18nc("yes, recurring to-do", "Yes");
                }
            } else {
                return i18nc("no, not a recurring to-do", "No");
            }
        case PriorityColumn:
            if (todo->priority() == 0) {
                return QVariant(QStringLiteral("--"));
            }
            return QVariant(todo->priority());
        case PercentColumn:
            return QVariant(todo->percentComplete());
        case StartDateColumn:
            return todo->hasStartDate() ? QLocale().toString(todo->dtStart().toLocalTime().date(), QLocale::ShortFormat) : QVariant(QString());
        case DueDateColumn:
            return todo->hasDueDate() ? QLocale().toString(todo->dtDue().toLocalTime().date(), QLocale::ShortFormat) : QVariant(QString());
        case CategoriesColumn: {
            QString categories = todo->categories().join(i18nc("delimiter for joining category/tag names", ","));
            return QVariant(categories);
        }
        case DescriptionColumn:
            return QVariant(todo->description());
        case CalendarColumn:
            return QVariant(CalendarSupport::displayName(d->m_calendar.data(), item.parentCollection()));
        }
        return QVariant();
    }

    if (role == Qt::EditRole) {
        switch (index.column()) {
        case SummaryColumn:
            return QVariant(todo->summary());
        case RecurColumn:
            return QVariant(todo->recurs());
        case PriorityColumn:
            return QVariant(todo->priority());
        case PercentColumn:
            return QVariant(todo->percentComplete());
        case StartDateColumn:
            return QVariant(todo->dtStart().date());
        case DueDateColumn:
            return QVariant(todo->dtDue().date());
        case CategoriesColumn:
            return QVariant(todo->categories());
        case DescriptionColumn:
            return QVariant(todo->description());
        case CalendarColumn:
            return QVariant(CalendarSupport::displayName(d->m_calendar.data(), item.parentCollection()));
        }
        return QVariant();
    }

    // set the tooltip for every item
    if (role == Qt::ToolTipRole) {
        if (d->m_preferences->enableToolTips()) {
            return QVariant(
                KCalUtils::IncidenceFormatter::toolTipStr(CalendarSupport::displayName(d->m_calendar.data(), item.parentCollection()), todo, QDate(), true));
        } else {
            return QVariant();
        }
    }

    // background colour for todos due today or overdue todos
    if (role == Qt::BackgroundRole) {
        if (todo->isOverdue()) {
            return QVariant(QBrush(d->m_preferences->todoOverdueColor()));
        } else if (isDueToday(todo)) {
            return QVariant(QBrush(d->m_preferences->todoDueTodayColor()));
        }
    }

    // indicate if a row is checked (=completed) only in the first column
    if (role == Qt::CheckStateRole && index.column() == 0) {
        if (hasChildren(index) && !index.parent().isValid()) {
            return QVariant();
        }

        if (todo->isCompleted()) {
            return QVariant(Qt::Checked);
        } else {
            return QVariant(Qt::Unchecked);
        }
    }

    // icon for recurring todos
    // It's in the summary column so you don't accidentally click
    // the checkbox ( which increments the next occurrence date ).
    if (role == Qt::DecorationRole && index.column() == SummaryColumn) {
        if (todo->recurs()) {
            return QVariant(QIcon::fromTheme(QStringLiteral("task-recurring")));
        }
    }

    // category colour
    if (role == Qt::DecorationRole && index.column() == SummaryColumn) {
        QStringList categories = todo->categories();
        return categories.isEmpty() ? QVariant() : QVariant(CalendarSupport::KCalPrefs::instance()->categoryColor(categories.first()));
    } else if (role == Qt::DecorationRole) {
        return QVariant();
    }

    if (role == TodoRole) {
        return QVariant::fromValue(item);
    }

    if (role == IsRichTextRole) {
        if (index.column() == SummaryColumn) {
            return QVariant(todo->summaryIsRich());
        } else if (index.column() == DescriptionColumn) {
            return QVariant(todo->descriptionIsRich());
        } else {
            return QVariant();
        }
    }

    if (role == Qt::TextAlignmentRole) {
        switch (index.column()) {
        // If you change this, change headerData() too.
        case RecurColumn:
        case PriorityColumn:
        case PercentColumn:
        case StartDateColumn:
        case DueDateColumn:
        case CategoriesColumn:
        case CalendarColumn:
            return QVariant(Qt::AlignHCenter | Qt::AlignVCenter);
        }
        return QVariant(Qt::AlignLeft | Qt::AlignVCenter);
    }

    if (sourceModel()) {
        return sourceModel()->data(mapToSource(index.sibling(index.row(), 0)), role);
    }

    return QVariant();
}

bool TodoModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    Q_ASSERT(index.isValid());
    if (!d->m_changer) {
        return false;
    }
    const QVariant oldValue = data(index, role);

    if (oldValue == value) {
        // Nothing changed, the user used one of the QStyledDelegate's editors but seted the old value
        // Lets just skip this then and avoid a roundtrip to akonadi, and avoid sending invitations
        return true;
    }

    const auto item = data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    const KCalendarCore::Todo::Ptr todo = CalendarSupport::todo(item);

    if (!item.isValid() || !todo) {
        //qCWarning(CALENDARVIEW_LOG) << "TodoModel::setData() called, bug item is invalid or doesn't have payload";
        Q_ASSERT(false);
        return false;
    }

    if (d->m_calendar->hasRight(item, Akonadi::Collection::CanChangeItem)) {
        KCalendarCore::Todo::Ptr oldTodo(todo->clone());
        if (role == Qt::CheckStateRole && index.column() == 0) {
            const bool checked = static_cast<Qt::CheckState>(value.toInt()) == Qt::Checked;
            if (checked) {
                todo->setCompleted(QDateTime::currentDateTimeUtc()); // Because it calls Todo::recurTodo()
            } else {
                todo->setCompleted(false);
            }
        }

        if (role == Qt::EditRole) {
            switch (index.column()) {
            case SummaryColumn:
                if (!value.toString().isEmpty()) {
                    todo->setSummary(value.toString());
                }
                break;
            case PriorityColumn:
                todo->setPriority(value.toInt());
                break;
            case PercentColumn:
                todo->setPercentComplete(value.toInt());
                break;
            case StartDateColumn: {
                QDateTime tmp = todo->dtStart();
                tmp.setDate(value.toDate());
                todo->setDtStart(tmp);
                break;
            }
            case DueDateColumn: {
                QDateTime tmp = todo->dtDue();
                tmp.setDate(value.toDate());
                todo->setDtDue(tmp);
                break;
            }
            case CategoriesColumn:
                todo->setCategories(value.toStringList());
                break;
            case DescriptionColumn:
                todo->setDescription(value.toString());
                break;
            }
        }

        if (!todo->dirtyFields().isEmpty()) {
            d->m_changer->modifyIncidence(item, oldTodo);
            // modifyIncidence will eventually call the view's
            // changeIncidenceDisplay method, which in turn
            // will call processChange. processChange will then emit
            // dataChanged to the view, so we don't have to
            // do it here
        }

        return true;
    } else {
        if (!(role == Qt::CheckStateRole && index.column() == 0)) {
            // KOHelper::showSaveIncidenceErrorMsg( 0, todo ); //TODO pass parent
            //qCCritical(CALENDARVIEW_LOG) << "Unable to modify incidence";
        }
        return false;
    }
}

int TodoModel::rowCount(const QModelIndex &parent) const
{
    if (sourceModel()) {
        if (parent.isValid()) {
            QModelIndex parent_col0 = createIndex(parent.row(), 0, parent.internalPointer());
            return sourceModel()->rowCount(mapToSource(parent_col0));
        } else {
            return sourceModel()->rowCount();
        }
    }
    return 0;
}

int TodoModel::columnCount(const QModelIndex &) const
{
    return ColumnCount;
}

void TodoModel::setSourceModel(QAbstractItemModel *model)
{
    if (model == sourceModel()) {
        return;
    }

    beginResetModel();

    if (sourceModel()) {
        disconnect(sourceModel(), SIGNAL(dataChanged(QModelIndex, QModelIndex)), d, SLOT(onDataChanged(QModelIndex, QModelIndex)));
        disconnect(sourceModel(), SIGNAL(headerDataChanged(Qt::Orientation, int, int)), d, SLOT(onHeaderDataChanged(Qt::Orientation, int, int)));

        disconnect(sourceModel(), SIGNAL(rowsInserted(QModelIndex, int, int)), d, SLOT(onRowsInserted(QModelIndex, int, int)));

        disconnect(sourceModel(), SIGNAL(rowsRemoved(QModelIndex, int, int)), d, SLOT(onRowsRemoved(QModelIndex, int, int)));

        disconnect(sourceModel(), SIGNAL(rowsMoved(QModelIndex, int, int, QModelIndex, int)), d, SLOT(onRowsMoved(QModelIndex, int, int, QModelIndex, int)));

        disconnect(sourceModel(), SIGNAL(rowsAboutToBeInserted(QModelIndex, int, int)), d, SLOT(onRowsAboutToBeInserted(QModelIndex, int, int)));

        disconnect(sourceModel(), SIGNAL(rowsAboutToBeRemoved(QModelIndex, int, int)), d, SLOT(onRowsAboutToBeRemoved(QModelIndex, int, int)));

        disconnect(sourceModel(), SIGNAL(modelAboutToBeReset()), d, SLOT(onModelAboutToBeReset()));

        disconnect(sourceModel(), SIGNAL(modelReset()), d, SLOT(onModelReset()));

        disconnect(sourceModel(), SIGNAL(layoutAboutToBeChanged()), d, SLOT(onLayoutAboutToBeChanged()));

        disconnect(sourceModel(), SIGNAL(layoutChanged()), d, SLOT(onLayoutChanged()));
    }

    QAbstractProxyModel::setSourceModel(model);

    if (sourceModel()) {
        connect(sourceModel(), SIGNAL(dataChanged(QModelIndex, QModelIndex)), d, SLOT(onDataChanged(QModelIndex, QModelIndex)));

        connect(sourceModel(), SIGNAL(headerDataChanged(Qt::Orientation, int, int)), d, SLOT(onHeaderDataChanged(Qt::Orientation, int, int)));

        connect(sourceModel(), SIGNAL(rowsAboutToBeInserted(QModelIndex, int, int)), d, SLOT(onRowsAboutToBeInserted(QModelIndex, int, int)));

        connect(sourceModel(), SIGNAL(rowsInserted(QModelIndex, int, int)), d, SLOT(onRowsInserted(QModelIndex, int, int)));

        connect(sourceModel(), SIGNAL(rowsAboutToBeRemoved(QModelIndex, int, int)), d, SLOT(onRowsAboutToBeRemoved(QModelIndex, int, int)));

        connect(sourceModel(), SIGNAL(rowsRemoved(QModelIndex, int, int)), d, SLOT(onRowsRemoved(QModelIndex, int, int)));

        connect(sourceModel(),
                SIGNAL(rowsAboutToBeMoved(QModelIndex, int, int, QModelIndex, int)),
                d,
                SLOT(onRowsAboutToBeMoved(QModelIndex, int, int, QModelIndex, int)));

        connect(sourceModel(), SIGNAL(rowsMoved(QModelIndex, int, int, QModelIndex, int)), d, SLOT(onRowsMoved(QModelIndex, int, int, QModelIndex, int)));

        connect(sourceModel(), SIGNAL(modelAboutToBeReset()), d, SLOT(onModelAboutToBeReset()));

        connect(sourceModel(), SIGNAL(modelReset()), d, SLOT(onModelReset()));

        connect(sourceModel(), SIGNAL(layoutAboutToBeChanged()), d, SLOT(onLayoutAboutToBeChanged()));

        connect(sourceModel(), SIGNAL(layoutChanged()), d, SLOT(onLayoutChanged()));
    }

    endResetModel();
}

void TodoModel::setIncidenceChanger(Akonadi::IncidenceChanger *changer)
{
    d->m_changer = changer;
}

QVariant TodoModel::headerData(int column, Qt::Orientation orientation, int role) const
{
    if (orientation != Qt::Horizontal) {
        return QVariant();
    }

    if (role == Qt::DisplayRole) {
        switch (column) {
        case SummaryColumn:
            return QVariant(i18n("Summary"));
        case RecurColumn:
            return QVariant(i18n("Recurs"));
        case PriorityColumn:
            return QVariant(i18n("Priority"));
        case PercentColumn:
            return QVariant(i18nc("@title:column percent complete", "Complete"));
        case StartDateColumn:
            return QVariant(i18n("Start Date"));
        case DueDateColumn:
            return QVariant(i18n("Due Date"));
        case CategoriesColumn:
            return QVariant(i18n("Tags"));
        case DescriptionColumn:
            return QVariant(i18n("Description"));
        case CalendarColumn:
            return QVariant(i18n("Calendar"));
        }
    }

    if (role == Qt::TextAlignmentRole) {
        switch (column) {
        // If you change this, change data() too.
        case RecurColumn:
        case PriorityColumn:
        case PercentColumn:
        case StartDateColumn:
        case DueDateColumn:
        case CategoriesColumn:
        case CalendarColumn:
            return QVariant(Qt::AlignHCenter);
        }
        return QVariant();
    }
    return QVariant();
}

void TodoModel::setCalendar(const Akonadi::ETMCalendar::Ptr &calendar)
{
    d->m_calendar = calendar;
}

Qt::DropActions TodoModel::supportedDropActions() const
{
    // Qt::CopyAction not supported yet
    return Qt::MoveAction;
}

QStringList TodoModel::mimeTypes() const
{
    static QStringList list;
    if (list.isEmpty()) {
        list << KCalUtils::ICalDrag::mimeType() << KCalUtils::VCalDrag::mimeType();
    }
    return list;
}

QMimeData *TodoModel::mimeData(const QModelIndexList &indexes) const
{
    Akonadi::Item::List items;
    for (const QModelIndex &index : indexes) {
        const auto item = this->data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (item.isValid() && !items.contains(item)) {
            items.push_back(item);
        }
    }
    return CalendarSupport::createMimeData(items);
}

bool TodoModel::dropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent)
{
    Q_UNUSED(row)
    Q_UNUSED(column)

    if (action != Qt::MoveAction) {
        //qCWarning(CALENDARVIEW_LOG) << "No action other than MoveAction currently supported!"; // TODO
        return false;
    }

    if (d->m_calendar && d->m_changer && (KCalUtils::ICalDrag::canDecode(data) || KCalUtils::VCalDrag::canDecode(data))) {
        KCalUtils::DndFactory dndFactory(d->m_calendar);
        KCalendarCore::Todo::Ptr t = dndFactory.createDropTodo(data);
        KCalendarCore::Event::Ptr e = dndFactory.createDropEvent(data);

        if (t) {
            // we don't want to change the created todo, but the one which is already
            // stored in our calendar / tree
            const Akonadi::Item item = d->findItemByUid(t->uid(), QModelIndex());
            KCalendarCore::Todo::Ptr todo = CalendarSupport::todo(item);
            KCalendarCore::Todo::Ptr destTodo;
            if (parent.isValid()) {
                const auto parentItem = this->data(parent, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
                if (parentItem.isValid()) {
                    destTodo = CalendarSupport::todo(parentItem);
                }
            }

            KCalendarCore::Incidence::Ptr tmp = destTodo;
            while (tmp) {
                if (tmp->uid() == todo->uid()) { // correct, don't use instanceIdentifier() here
                    KMessageBox::information(nullptr,
                                             i18n("Cannot move to-do to itself or a child of itself."),
                                             i18n("Drop To-do"),
                                             QStringLiteral("NoDropTodoOntoItself"));
                    return false;
                }
                const QString parentUid = tmp->relatedTo();
                tmp = CalendarSupport::incidence(d->m_calendar->item(parentUid));
            }

            if (!destTodo || !destTodo->hasRecurrenceId()) {
                KCalendarCore::Todo::Ptr oldTodo = KCalendarCore::Todo::Ptr(todo->clone());
                // destTodo is empty when we drag a to-do out of a relationship
                todo->setRelatedTo(destTodo ? destTodo->uid() : QString());
                d->m_changer->modifyIncidence(item, oldTodo);

                // again, no need to Q_EMIT dataChanged, that's done by processChange
                return true;
            } else {
                //qCDebug(CALENDARVIEW_LOG) << "Todo's with recurring id can't have child todos yet.";
                return false;
            }
        } else if (e) {
            // TODO: Implement dropping an event onto a to-do: Generate a relationship to the event!
        } else {
            if (!parent.isValid()) {
                // TODO we should create a new todo with the data in the drop object
                //qCDebug(CALENDARVIEW_LOG) << "TODO: Create a new todo with the given data";
                return false;
            }

            const auto parentItem = this->data(parent, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
            KCalendarCore::Todo::Ptr destTodo = CalendarSupport::todo(parentItem);

            if (data->hasText()) {
                QString text = data->text();

                KCalendarCore::Todo::Ptr oldTodo = KCalendarCore::Todo::Ptr(destTodo->clone());

                if (text.startsWith(QLatin1String("file:"))) {
                    destTodo->addAttachment(KCalendarCore::Attachment(text));
                } else {
                    QStringList emails = KEmailAddress::splitAddressList(text);
                    for (QStringList::ConstIterator it = emails.constBegin(); it != emails.constEnd(); ++it) {
                        QString name, email, comment;
                        if (KEmailAddress::splitAddress(*it, name, email, comment) == KEmailAddress::AddressOk) {
                            destTodo->addAttendee(KCalendarCore::Attendee(name, email));
                        }
                    }
                }
                d->m_changer->modifyIncidence(parentItem, oldTodo);
                return true;
            }
        }
    }

    return false;
}

Qt::ItemFlags TodoModel::flags(const QModelIndex &index) const
{
    if (!index.isValid()) {
        return Qt::NoItemFlags;
    }

    Qt::ItemFlags ret = QAbstractItemModel::flags(index);

    const auto item = data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();

    if (!item.isValid()) {
        Q_ASSERT(mapToSource(index).isValid());
        //qCWarning(CALENDARVIEW_LOG) << "Item is invalid " << index;
        Q_ASSERT(false);
        return Qt::NoItemFlags;
    }

    ret |= Qt::ItemIsDragEnabled;

    const KCalendarCore::Todo::Ptr todo = CalendarSupport::todo(item);

    if (d->m_calendar->hasRight(item, Akonadi::Collection::CanChangeItem)) {
        // the following columns are editable:
        switch (index.column()) {
        case SummaryColumn:
        case PriorityColumn:
        case PercentColumn:
        case StartDateColumn:
        case DueDateColumn:
        case CategoriesColumn:
            ret |= Qt::ItemIsEditable;
            break;
        case DescriptionColumn:
            if (!todo->descriptionIsRich()) {
                ret |= Qt::ItemIsEditable;
            }
            break;
        }
    }

    if (index.column() == 0) {
        // whole rows should have checkboxes, so append the flag for the
        // first item of every row only. Also, only the first item of every
        // row should be used as a target for a drag and drop operation.
        ret |= Qt::ItemIsUserCheckable | Qt::ItemIsDropEnabled;
    }
    return ret;
}

QModelIndex TodoModel::mapFromSource(const QModelIndex &sourceIndex) const
{
    if (!sourceModel() || !sourceIndex.isValid()) {
        return {};
    }

    Q_ASSERT(sourceIndex.internalPointer());

    return createIndex(sourceIndex.row(), 0, sourceIndex.internalPointer());
}

QModelIndex TodoModel::mapToSource(const QModelIndex &proxyIndex) const
{
    if (!sourceModel() || !proxyIndex.isValid()) {
        return {};
    }

    if (proxyIndex.column() != 0) {
        //qCCritical(CALENDARVIEW_LOG) << "Map to source called with column>0, but source model only has 1 column";
        Q_ASSERT(false);
    }

    Q_ASSERT(proxyIndex.internalPointer());

    // we convert to column 0
    const QModelIndex sourceIndex = SourceModelIndex(proxyIndex.row(), 0, proxyIndex.internalPointer(), sourceModel());

    return sourceIndex;
}

QModelIndex TodoModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!sourceModel()) {
        return QModelIndex();
    }

    Q_ASSERT(!parent.isValid() || parent.internalPointer());
    QModelIndex parent_col0 = parent.isValid() ? createIndex(parent.row(), 0, parent.internalPointer()) : QModelIndex();

    // Lets preserve the original internalPointer
    const QModelIndex index = mapFromSource(sourceModel()->index(row, 0, mapToSource(parent_col0)));

    Q_ASSERT(!index.isValid() || index.internalPointer());

    if (index.isValid()) {
        return createIndex(row, column, index.internalPointer());
    }

    return {};
}

QModelIndex TodoModel::parent(const QModelIndex &child) const
{
    if (!sourceModel() || !child.isValid()) {
        return QModelIndex();
    }

    Q_ASSERT(child.internalPointer());
    const QModelIndex child_col0 = createIndex(child.row(), 0, child.internalPointer());
    QModelIndex parentIndex = mapFromSource(sourceModel()->parent(mapToSource(child_col0)));

    Q_ASSERT(!parentIndex.isValid() || parentIndex.internalPointer());
    if (parentIndex.isValid()) { // preserve original column
        return createIndex(parentIndex.row(), child.column(), parentIndex.internalPointer());
    }

    return {};
}

QModelIndex TodoModel::buddy(const QModelIndex &index) const
{
    // We reimplement because the default implementation calls mapToSource() and
    // source model doesn't have the same number of columns.
    return index;
}

QHash<int, QByteArray> TodoModel::roleNames() const
{
    return {{SummaryRole, QByteArrayLiteral("summary")},
            {RecurRole, QByteArrayLiteral("recur")},
            {PriorityRole, QByteArrayLiteral("priority")},
            {PercentRole, QByteArrayLiteral("percent")},
            {StartDateRole, QByteArrayLiteral("startDate")},
            {DueDateRole, QByteArrayLiteral("dueDate")},
            {CategoriesRole, QByteArrayLiteral("categories")},
            {DescriptionRole, QByteArrayLiteral("description")},
            {CalendarRole, QByteArrayLiteral("calendar")},
            {Qt::CheckStateRole, QByteArrayLiteral("checked")}};
}
