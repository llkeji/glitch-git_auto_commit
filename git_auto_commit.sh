#!/bin/bash

# 配置
IFS=',' read -ra GIT_URLS <<< "${GIT_URL}"
IFS=',' read -ra GIT_TOKENS <<< "${GIT_TOKEN}"
IFS=',' read -ra GIT_USERNAMES <<< "${GIT_USERNAME}"
IFS=',' read -ra GIT_EMAILS <<< "${GIT_EMAIL}"
DATE=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
MAX_SIZE=512000
# 循环处理每个仓库
for i in "${!GIT_URLS[@]}"; do

  USERNAME=${GIT_USERNAMES[i]}
  # 设置git配置
  git config --global user.name "${USERNAME}"
  git config --global user.email "${GIT_EMAILS[i]}"

  echo "开始处理仓库：${GIT_URLS[i]}"

  REPO_DIR="/tmp/repo-${USERNAME}"
  # 克隆仓库
  if [ -d "${REPO_DIR}" ]; then
    echo "目录 ${REPO_DIR} 已存在，跳过克隆操作"
  else
    git clone https://${GIT_TOKENS[i]}@${GIT_URLS[i]#https://} "${REPO_DIR}"
  fi

  cd "${REPO_DIR}"
  
  # 创建或更新commit.txt文件
  if [ -f commit.txt ]; then 
    if [ $(stat -c%s "commit.txt") -gt $MAX_SIZE ]; then
      > commit.txt
    fi
    sed -i "1i提交时间： $DATE, 用户名： ${USERNAME}" commit.txt
  else
    echo 提交时间： $DATE, 用户名： ${USERNAME} >> commit.txt
  fi

  # 创建或更新commitAll.txt文件
  if [ -f /app/commitAll.txt ]; then 
    if [ $(stat -c%s "/app/commitAll.txt") -gt $MAX_SIZE ]; then
      > /app/commitAll.txt
    fi
    sed -i "1i提交时间： $DATE, 用户名： ${USERNAME}" /app/commitAll.txt
  else
    echo 提交时间： $DATE, 用户名： ${USERNAME} >> /app/commitAll.txt
  fi

  # 添加所有更改
  git add .

  # 提交更改
  git commit -m "test: add now time - $DATE"

  # 推送更改
  git push origin main

  echo "仓库：${GIT_URLS[i]}处理完成"
  
  rm -rf $REPO_DIR

  cd ~/
  
done