import tweepy
import pandas as pd
import sqlite3
import logging

logging.basicConfig(filename='log.txt', level=logging.INFO)

def get_following(id, client):
    following_ids = []
    for page in tweepy.Paginator(client.get_users_following, id, max_results=1000):
        following_ids.extend([user['id'] for user in page.data])
    return following_ids

# connect to SQLite database
conn = sqlite3.connect('twitter_data.db')
c = conn.cursor()

# create tables in the SQLite database
c.execute('''
    CREATE TABLE IF NOT EXISTS FollowData
    (User1 TEXT NOT NULL,
    User2 TEXT NOT NULL,
    FollowEachOther BOOLEAN NOT NULL);
''')

c.execute('''
    CREATE TABLE IF NOT EXISTS UserFollowing
    (UserId TEXT NOT NULL,
    FollowingId TEXT NOT NULL);
''')

# Load data from CSV
finalTable = pd.read_csv('finalTable.csv', dtype=str)

# Replace with your list of user ids
author_id = finalTable['author_id'].unique().tolist()
twitter_id = finalTable['twitter_id'].unique().tolist()

#combine two list
user_ids = author_id + twitter_id

# get uniwue user_ids
user_ids = list(set(user_ids))

logging.info(f"Found {len(user_ids)} users to process.")

# Replace with your Bearer token
client = tweepy.Client(bearer_token="AAAAAAAAAAAAAAAAAAAAAGYKkQEAAAAAbNiwJ4AF4PTE8km%2FFTVoB7ewbds%3Dv7YaQmbfxG4r6NnkRvvqfeysnZ0ylCf3EIOHHiKzMRxomN8w4l",
                       wait_on_rate_limit=True)

user_following = {user_id: get_following(user_id, client) for user_id in user_ids}

for user_id in user_ids:
    logging.info(f"Fetching following ids for user {user_id}.")
    following = get_following(user_id, client)
    user_following[user_id] = following
    logging.info(f"User {user_id} is following {len(following)} users.")
    # Insert the following ids into the UserFollowing table
    for following_id in following:
        c.execute("INSERT INTO UserFollowing (UserId, FollowingId) VALUES (?, ?)",
                  (user_id, following_id))

logging.info("Finished fetching following ids for all users.")

for i in range(len(user_ids)):
    for j in range(i + 1, len(user_ids)):
        logging.info(f"Checking if users {user_ids[i]} and {user_ids[j]} follow each other.")
        result = user_ids[j] in user_following[user_ids[i]] and user_ids[i] in user_following[user_ids[j]]
        if result:
            logging.info(f"Users {user_ids[i]} and {user_ids[j]} follow each other.")
        else:
            logging.info(f"Users {user_ids[i]} and {user_ids[j]} do not follow each other.")
        c.execute("INSERT INTO FollowData (User1, User2, FollowEachOther) VALUES (?, ?, ?)",
                  (user_ids[i], user_ids[j], result))

logging.info("Finished processing all users.")

# commit your changes and close the connection
conn.commit()
conn.close()
