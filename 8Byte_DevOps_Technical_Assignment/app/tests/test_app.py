from app import app

def test_healthz():
    response = app.test_client().get('/healthz')
    assert response.status_code == 200
    assert response.json['status'] == 'ok'

def test_readyz():
    response = app.test_client().get('/readyz')
    assert response.status_code == 200
    assert response.json['status'] == 'ready'
