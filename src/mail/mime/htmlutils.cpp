// SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "htmlutils.h"

#include <QMap>
#include <QUrl>

static QString resolveEntities(const QString &in)
{
    QString out;

    for (int i = 0; i < (int)in.length(); ++i) {
        if (in[i] == QLatin1Char('&')) {
            // find a semicolon
            ++i;
            int n = in.indexOf(QLatin1Char(';'), i);
            if (n == -1) {
                break;
            }
            QString type = in.mid(i, (n - i));
            i = n; // should be n+1, but we'll let the loop increment do it

            if (type == QLatin1String("amp")) {
                out += QLatin1Char('&');
            } else if (type == QLatin1String("lt"))
                out += QLatin1Char('<');
            else if (type == QLatin1String("gt"))
                out += QLatin1Char('>');
            else if (type == QLatin1String("quot"))
                out += QLatin1Char('\"');
            else if (type == QLatin1String("apos"))
                out += QLatin1Char('\'');
            else if (type == QLatin1String("nbsp"))
                out += QChar(0xa0);
        } else {
            out += in[i];
        }
    }

    return out;
}

static bool linkify_pmatch(const QString &str1, int at, const QString &str2)
{
    if (str2.length() > (str1.length() - at))
        return false;

    for (int n = 0; n < (int)str2.length(); ++n) {
        if (str1.at(n + at).toLower() != str2.at(n).toLower())
            return false;
    }

    return true;
}

static bool linkify_isOneOf(const QChar &c, const QString &charlist)
{
    for (int i = 0; i < (int)charlist.length(); ++i) {
        if (c == charlist.at(i))
            return true;
    }

    return false;
}

// encodes a few dangerous html characters
static QString linkify_htmlsafe(const QString &in)
{
    QString out;

    for (int n = 0; n < in.length(); ++n) {
        if (linkify_isOneOf(in.at(n), QStringLiteral("\"\'`<>"))) {
            // hex encode
            QString hex;
            hex.asprintf("%%%02X", in.at(n).toLatin1());
            out.append(hex);
        } else {
            out.append(in.at(n));
        }
    }

    return out;
}

static bool linkify_okUrl(const QString &url)
{
    if (url.at(url.length() - 1) == QLatin1Char('.'))
        return false;

    return true;
}

static bool linkify_okEmail(const QString &addy)
{
    // this makes sure that there is an '@' and a '.' after it, and that there is
    // at least one char for each of the three sections
    int n = addy.indexOf(QLatin1Char('@'));
    if (n == -1 || n == 0)
        return false;
    int d = addy.indexOf(QLatin1Char('.'), n + 1);
    if (d == -1 || d == 0)
        return false;
    if ((addy.length() - 1) - d <= 0)
        return false;
    if (addy.indexOf(QStringLiteral("..")) != -1)
        return false;

    return true;
}

/**
 * takes a richtext string and heuristically adds links for uris of common protocols
 * @return a richtext string with link markup added
 */
QString HtmlUtils::linkify(const QString &in)
{
    QString out = in;
    int x1, x2;
    bool isUrl, isAtStyle;
    QString linked, link, href;

    for (int n = 0; n < (int)out.length(); ++n) {
        isUrl = false;
        isAtStyle = false;
        x1 = n;

        if (linkify_pmatch(out, n, QStringLiteral("xmpp:"))) {
            n += 5;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("mailto:"))) {
            n += 7;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("http://"))) {
            n += 7;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("https://"))) {
            n += 8;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("ftp://"))) {
            n += 6;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("news://"))) {
            n += 7;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("ed2k://"))) {
            n += 7;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("magnet:"))) {
            n += 7;
            isUrl = true;
            href = QString();
        } else if (linkify_pmatch(out, n, QStringLiteral("www."))) {
            isUrl = true;
            href = QStringLiteral("http://");
        } else if (linkify_pmatch(out, n, QStringLiteral("ftp."))) {
            isUrl = true;
            href = QStringLiteral("ftp://");
        } else if (linkify_pmatch(out, n, QStringLiteral("@"))) {
            isAtStyle = true;
            href = QStringLiteral("x-psi-atstyle:");
        }

        if (isUrl) {
            // make sure the previous char is not alphanumeric
            if (x1 > 0 && out.at(x1 - 1).isLetterOrNumber())
                continue;

            // find whitespace (or end)
            QMap<QChar, int> brackets;
            brackets[QLatin1Char('(')] = brackets[QLatin1Char(')')] = brackets[QLatin1Char('[')] = brackets[QLatin1Char(']')] = brackets[QLatin1Char('{')] =
                brackets[QLatin1Char('}')] = 0;
            QMap<QChar, QChar> openingBracket;
            openingBracket[QLatin1Char(')')] = QLatin1Char('(');
            openingBracket[QLatin1Char(']')] = QLatin1Char('[');
            openingBracket[QLatin1Char('}')] = QLatin1Char('{');
            for (x2 = n; x2 < (int)out.length(); ++x2) {
                if (out.at(x2).isSpace() || linkify_isOneOf(out.at(x2), QStringLiteral("\"\'`<>")) || linkify_pmatch(out, x2, QStringLiteral("&quot;"))
                    || linkify_pmatch(out, x2, QStringLiteral("&apos;")) || linkify_pmatch(out, x2, QStringLiteral("&gt;"))
                    || linkify_pmatch(out, x2, QStringLiteral("&lt;"))) {
                    break;
                }
                if (brackets.contains(out.at(x2))) {
                    ++brackets[out.at(x2)];
                }
            }
            int len = x2 - x1;
            QString pre = resolveEntities(out.mid(x1, x2 - x1));

            // go backward hacking off unwanted punctuation
            int cutoff;
            for (cutoff = pre.length() - 1; cutoff >= 0; --cutoff) {
                if (!linkify_isOneOf(pre.at(cutoff), QStringLiteral("!?,.()[]{}<>\"")))
                    break;
                if (linkify_isOneOf(pre.at(cutoff), QStringLiteral(")]}")) && brackets[pre.at(cutoff)] - brackets[openingBracket[pre.at(cutoff)]] <= 0) {
                    break; // in theory, there could be == above, but these are urls, not math ;)
                }
                if (brackets.contains(pre.at(cutoff))) {
                    --brackets[pre.at(cutoff)];
                }
            }
            ++cutoff;
            //++x2;

            link = pre.mid(0, cutoff);
            if (!linkify_okUrl(link)) {
                n = x1 + link.length();
                continue;
            }
            href += link;
            // attributes need to be encoded too.
            href = href.toHtmlEscaped();
            href = linkify_htmlsafe(href);
            // printf("link: [%s], href=[%s]\n", link.latin1(), href.latin1());
            linked = QStringLiteral("<a href=\"%1\">").arg(href) + QUrl{link}.toDisplayString(QUrl::RemoveQuery) + QStringLiteral("</a>")
                + pre.mid(cutoff).toHtmlEscaped();
            out.replace(x1, len, linked);
            n = x1 + linked.length() - 1;
        } else if (isAtStyle) {
            // go backward till we find the beginning
            if (x1 == 0)
                continue;
            --x1;
            for (; x1 >= 0; --x1) {
                if (!linkify_isOneOf(out.at(x1), QStringLiteral("_.-+")) && !out.at(x1).isLetterOrNumber())
                    break;
            }
            ++x1;

            // go forward till we find the end
            x2 = n + 1;
            for (; x2 < (int)out.length(); ++x2) {
                if (!linkify_isOneOf(out.at(x2), QStringLiteral("_.-+")) && !out.at(x2).isLetterOrNumber())
                    break;
            }

            int len = x2 - x1;
            link = out.mid(x1, len);
            // link = resolveEntities(link);

            if (!linkify_okEmail(link)) {
                n = x1 + link.length();
                continue;
            }

            href += link;
            // printf("link: [%s], href=[%s]\n", link.latin1(), href.latin1());
            linked = QStringLiteral("<a href=\"%1\">").arg(href) + link + QStringLiteral("</a>");
            out.replace(x1, len, linked);
            n = x1 + linked.length() - 1;
        }
    }

    return out;
}
