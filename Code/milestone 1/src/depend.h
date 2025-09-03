#pragma once

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>
using namespace std;
class Node{
    static int node_count;
    public:
        string node_label;
        int node_index;
        bool is_terminal;
        int node_token;
        void set_label(string label);
        void set_terminal();
        void set_token(int token);
};
class Semantic_Data{
    public:
        Node* node_ptr;
};
Node * make_new_node(string label);
void add_edge(Node * from_node_ptr, Node * to_node_ptr);
void add_edge(Node * from_node_ptr, vector<Node *> to_node_ptr_vec);
void make_ast();
