import networkx as nx
def read(filepath):
    G = nx.Graph()
    with open(filepath, 'r') as file:
        line = file.readline()
        n = int(line.strip().split(" ")[1])
        for _ in range(n):
            parts = file.readline().strip().split("!")
            id = int(parts[0])
            name = parts[1]
            label = parts[2].strip()
            G.add_node(id, name=name, label=label)
        line = file.readline()
        m = int(line.strip().split(" ")[1])
        for _ in range(m):
            parts = file.readline().strip().split(" ")
            G.add_edge(int(parts[0]), int(parts[1]))
    return G


filepath = "works.net"
G = read(filepath)
n = G.number_of_nodes()
m = G.number_of_edges()
print(n)
print(m)