import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import time
import json
import os
import dotenv as dt
import matplotlib.pyplot as plt


dt.load_dotenv(dotenv_path='.env')


def authenticate(interval):
    client_id = os.getenv(f"CLIENT_ID_{interval}")
    client_secret = os.getenv(f"CLIENT_SECRET_{interval}")
    
    client_credentials_manager = SpotifyClientCredentials(client_id=client_id, client_secret=client_secret)
    sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
    return sp


def get_uuid(track_name, sp):
    search_results = sp.search(q=track_name, type='track', limit=1)

    # Extract UUID of the first track (assuming it's the one you're looking for)
    if search_results['tracks']['items']:
        track_uuid = search_results['tracks']['items'][0]['id']
        return track_uuid
    else:
        return None
    

def get_popularity(track_uuid, sp):
    track_details = sp.track(track_uuid)
    popularity = track_details['popularity']
    return popularity


def save_dict(works):
    with open('works.json', 'w') as f:
        json.dump(works, f)
        print("Saved works to works.json")


def main():
    # obratno preberemo podatke
    with open('works.json', 'r') as f:
        works = json.load(f)

    indy = 0
    last_auth_time = time.time()
    start_time = time.time()

    sp = authenticate(0)
    interval = 0

    for node in G.nodes():
        if G.nodes[node]['label'] == 'Work':
            if str(node) in works.keys():
                continue
            current_time = time.time()  
            if current_time - last_auth_time > 300: 
                sp = authenticate(interval)
                interval = (interval + 1) % 5
                last_auth_time = current_time
            if indy % 500 == 0:
                save_dict(works)
            works[node] = {'name': G.nodes[node]['name']}  
            works[node]['uuid'] = get_uuid(works[node]['name'], sp)
            if works[node]['uuid'] is not None:
                works[node]['popularity'] = get_popularity(works[node]['uuid'], sp) + 1
                indy += 1
                if indy % 50 == 0: print(indy, time.time() - start_time)
            else:
                works[node]['popularity'] = 1
    
    save_dict(works)
    # obratno preberemo podatke
    with open('works.json', 'r') as f:
        works = json.load(f)

    popularity_values = [works[node]['popularity'] for node in works if 'popularity' in works[node]]

    plt.hist(popularity_values, bins=20, edgecolor='black')
    plt.xlabel('Popularity')
    plt.ylabel('Frequency')
    plt.title('Histogram of Popularity')
    plt.show()


if __name__ == "__main__":
    main()