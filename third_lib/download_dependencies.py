#!/usr/bin/env python3
import subprocess
import os

def clone_github_repositories(file_path):
    with open(file_path, 'r') as file:
        for line in file:
            # 去除行尾的换行符
            line = line.strip()
            if line.startswith('git@github.com:'):
                # 使用 git clone 命令克隆仓库
                try:
                    subprocess.run(['git', 'clone', line], check=True)
                    print(f'Successfully cloned {line}')
                except subprocess.CalledProcessError as e:
                    print(f'Failed to clone {line}: {e}')

# 调用函数，传入文件路径
clone_github_repositories('./third_lib.txt')