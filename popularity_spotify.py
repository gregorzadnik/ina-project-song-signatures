def get_tonality_of_node(G, node):
    for neigh in G.neighbors(node):
        if G.nodes()[neigh]['label'] == 'Key':
            return G.nodes()[neigh]['name']

import json

with open('works.json', 'r') as f:
    spotipy_works = json.load(f)

histogram_popularity = {}
pop_cum = 0
cnt_cum = 0
for key in spotipy_works:
    node = G.nodes()[int(key)-4]
    tonality = get_tonality_of_node(G, int(key)-4)
    if tonality not in histogram_popularity:
        histogram_popularity[tonality] = {}
        histogram_popularity[tonality]['popularity'] = 0
        histogram_popularity[tonality]['count'] = 0
    histogram_popularity[tonality]['popularity'] += spotipy_works[key]['popularity']
    pop_cum += spotipy_works[key]['popularity']
    histogram_popularity[tonality]['count'] += 1
    cnt_cum += 1
    
histogram_popularity_normalized = {k: v['popularity']/pop_cum for k, v in histogram_popularity.items()}

sum_cum_w1 = 0
for key in histogram_popularity_normalized.keys():
    histogram_popularity[key]['w1'] = cnt_cum / histogram_popularity[key]['count']
    sum_cum_w1 = sum_cum_w1 + histogram_popularity[key]['w1']

histogram_weighted = {}
sum_cum_w = 0
for key in histogram_popularity_normalized.keys():
    histogram_popularity[key]['weight'] = histogram_popularity[key]['w1'] / sum_cum_w1
    histogram_weighted[key] = histogram_popularity[key]['weight'] * histogram_popularity[key]['popularity']
    sum_cum_w += histogram_weighted[key]

histogram_weighted = {k: v/sum_cum_w for k, v in histogram_weighted.items()}

hw = {}
hp = {}
for key in labels:
    hw[key] = histogram_weighted[key]
    hp[key] = histogram_popularity_normalized[key]

plot_popularities(labels, [h for h in hp.values()], 
                  [h for h in hw.values()], 
                  'Popularity normalized', 'Popularity weighted', 
                  'Key popularity based on Spotify popularity')
