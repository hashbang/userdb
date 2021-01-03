import base64
import json
import os
import unittest

import jwt
import psycopg2
import requests


class IntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.conn = psycopg2.connect(
            database=os.environ.get("PGDATABASE", "userdb"),
            user=os.environ.get("PGUSER", "postgres"),
            password=os.environ.get("PGPASSWORD", None),
            host=os.environ.get("PGHOST", None),
            port=os.environ.get("PGPORT")
        )
        token = jwt.encode(
            {"role": "api-user-create"},
            key=os.environ.get("JWT_SECRET",
                "a_test_only_postgrest_jwt_secret"),
            algorithm="HS256",
            headers={"alg":"HS256"}
        )
        cls.headers = {
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        cls.auth_headers = {
            "Authorization": f"Bearer {token.decode('utf-8')}"
        }
        cls.auth_headers.update(cls.headers)
        cls.cleanDB(cls)

    @classmethod
    def tearDownClass(cls):
        cls.conn.close()

    def setUp(self):
        query = """
            INSERT INTO
                hosts (name,maxusers)
                VALUES ('test.hashbang.sh','500');
        """
        cur = self.conn.cursor()
        cur.execute(query)
        self.conn.commit()

    def tearDown(self):
        self.cleanDB()

    def cleanDB(self):
        cur = self.conn.cursor()
        cur.execute("TRUNCATE passwd, hosts, ssh_public_key, openpgp_public_key CASCADE;")
        self.conn.commit()

    def test_can_connect_to_api(self):
        """Can Connect to API Server"""
        url = "http://userdb-postgrest:3000/"
        res = requests.get(url)
        data = res.json()
        self.assertEqual(data["info"]["title"], "PostgREST API")


    def test_cannot_create_user_anonymously(self):
        """Cannot create user anonymously via PostgREST"""
        url = "http://userdb-postgrest:3000/passwd"
        data = {}
        with open("./keys/id_ed25519.pub", "r") as f:
            file_data = f.read().split('\n')
            post_body = {
                "name": "testuser",
                "host": "test.hashbang.sh",
                "data": {
                    "shell": "/bin/bash",
                    "ssh_keys": file_data
                }
            }
        res = requests.post(url, json=post_body, headers=self.headers)
        self.assertEqual(res.status_code, 401)
        data = res.json()
        self.assertIn("permission denied", data.get('message'))

    def test_cannot_create_user_with_invalid_host_and_valid_auth(self):
        """Can not create user with invalid host and valid auth via PostgREST"""
        url = "http://userdb-postgrest:3000/passwd"
        data = {}
        with open("./keys/id_ed25519.pub", "r") as f:
            file_data = f.read().split('\n')
            post_body = {
                "name": "testuser42",
                "host": "invalidbox.hashbang.sh",
                "data": {
                    "shell": "/bin/bash",
                    "ssh_keys": file_data
                }
            }
        res = requests.post(url, json=post_body, headers=self.auth_headers)
        res_data = res.json()
        self.assertEqual(res.status_code, 409)
        self.assertIn("violates foreign key constraint", res_data['message'])

    def test_can_create_user_with_valid_host_and_auth(self):
        """Can create user with a valid host and valid auth via PostgREST"""
        url = "http://userdb-postgrest:3000/passwd"
        data = {}
        with open("./keys/id_ed25519.pub", "r") as f:
            file_data = [key for key in f.read().split('\n') if key]
            post_body = {
                "name": "testuser43",
                "host": "test.hashbang.sh",
                "data": {
                    "shell": "/bin/bash",
                    "ssh_keys": file_data
                }
            }
        res = requests.post(url, json=post_body, headers=self.auth_headers)
        self.assertEqual(res.status_code, 201)

    def test_can_create_user_with_valid_host_and_ssh_key(self):
        """Can create user with a valid host and SSH key"""
        url = "http://userdb-postgrest:3000/signup"
        data = {}
        with open("./keys/id_ed25519.pub", "r") as f:
            file_data = [key for key in f.read().split('\n') if key]
            post_body = {
                "name": "testuser",
                "host": "test.hashbang.sh",
                "shell": "/bin/zsh",
                "keys": file_data
            }
        res = requests.post(url, json=post_body, headers=self.auth_headers)
        self.assertEqual(res.status_code, 201)

        res = requests.get('http://userdb-postgrest:3000/passwd?name=eq.testuser')
        res_data = res.json()[0]
        self.assertEqual(post_body["name"], res_data["name"])
        self.assertEqual(post_body["host"], res_data["host"])
        self.assertEqual(post_body["shell"], res_data["shell"])

    def test_can_add_openpgp_key_to_user(self):
        """Can Add OpenPGP key to User"""
        url = "http://userdb-postgrest:3000/signup"
        data = {}
        with open("./keys/id_ed25519.pub", "r") as f:
            file_data = [key for key in f.read().split('\n') if key]
            post_body = {
                "name": "testuser",
                "host": "test.hashbang.sh",
                "shell": "/bin/zsh",
                "keys": file_data
            }
        res = requests.post(url, json=post_body, headers=self.auth_headers)
        self.assertEqual(res.status_code, 201)
        res = requests.get('http://userdb-postgrest:3000/passwd?name=eq.testuser')
        res_id = res.json()[0]["uid"]
        with open("./keys/testuser.pub.asc") as f:
            file_data = f.read()
            post_body = {
                "uid": res_id,
                "ascii_armoured_public_key": file_data
            }
        res = requests.post(
            "http://userdb-postgrest:3000/openpgp_public_key",
            json=post_body,
            headers=self.auth_headers
        )
        self.assertEqual(201, res.status_code)

        res = requests.get(
            f"http://userdb-postgrest:3000/openpgp_public_key?uid=eq.{res_id}",
            headers=self.auth_headers
        )
        res_data = res.json()[0]
        self.assertEqual(res_data['ascii_armoured_public_key'], file_data)
