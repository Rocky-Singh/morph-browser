/*
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QDebug>

#include "cookie-store.h"


class CookieStoreRequest : public QObject
{
    Q_OBJECT

public:
    CookieStoreRequest(CookieStore* cookieStore,
        QObject* parent = 0) : _cookieStore(cookieStore) {}

    CookieStore* _cookieStore;

public Q_SLOTS:
    void cookiesReceived(const Cookies& cookies)
    {
        emit gotCookies(cookies, this);
    }
    void cookiesUpdated(bool status)
    {
        emit cookiesSet(status);
    }

Q_SIGNALS:
    void gotCookies(const Cookies& cookies, CookieStoreRequest* request);
    void cookiesSet(bool status);
};


CookieStore::CookieStore(QObject* parent):
    QObject(parent)
{
    qRegisterMetaType<QNetworkCookie>();
    qRegisterMetaType<Cookies>("Cookies");
}

void CookieStore::getCookies()
{
    doGetCookies();
}

void CookieStore::setCookies(const Cookies& cookies)
{
    doSetCookies(cookies);
}

void CookieStore::doGetCookies()
{
    Q_UNIMPLEMENTED();
}

void CookieStore::doSetCookies(const Cookies& cookies)
{
    Q_UNUSED(cookies);
    Q_UNIMPLEMENTED();
}

QDateTime CookieStore::lastUpdateTimeStamp() const
{
    return _lastUpdateTimeStamp;
}

void CookieStore::updateLastUpdateTimestamp(const QDateTime& timestamp)
{
    _lastUpdateTimeStamp = timestamp;
}

void CookieStore::cookiesUpdated(bool status)
{
    if (status)
        Q_EMIT moved(true);
    else
        Q_EMIT moved(false);
}

void CookieStore::cookiesReceived(const Cookies& cookies
                                  , CookieStoreRequest* request)
{
    if (Q_UNLIKELY(!request))
        return;

    delete request;

    connect(this, &CookieStore::cookiesSet,
            this, &CookieStore::cookiesUpdated);

    setCookies(cookies);
}

void CookieStore::moveFrom(CookieStore* store)
{
    if (Q_UNLIKELY(!store))
        return;

    QDateTime lastRemoteCookieUpdate = store->lastUpdateTimeStamp();
    QDateTime lastLocalCookieUpdate = lastUpdateTimeStamp();

    // Disabled for now since.
    // There is an obvious race if the WebView is instanciated
    // (since it creates a cookies db file at creation time).
    // But when delaying the creation, only using the WebContext to
    // access the cookieManager, and manually creating a cookies db file
    // if none is found (since the cookie manager does not create one
    // when setting its cookies), something fails.
#if 0
    if (lastRemoteCookieUpdate.isValid() &&
        lastLocalCookieUpdate.isValid() &&
        (lastRemoteCookieUpdate < lastLocalCookieUpdate))
    {
        Q_EMIT moved(false);
        return;
    }
#endif

    CookieStoreRequest* storeRequest = new CookieStoreRequest(store);
    _currentStoreRequests.insert(storeRequest, true);

    connect(store, &CookieStore::gotCookies,
            storeRequest, &CookieStoreRequest::cookiesReceived);

    connect(storeRequest, &CookieStoreRequest::gotCookies,
            this, &CookieStore::cookiesReceived);

    store->getCookies();
}

#include "cookie-store.moc"


