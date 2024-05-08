#!/bin/bash

# 配置
IFS=',' read -ra GIT_URLS <<< "${GIT_URL}"
IFS=',' read -ra GIT_TOKENS <<< "${GIT_TOKEN}"
IFS=',' read -ra GIT_EMAILS <<< "${GIT_EMAIL}"
DATE=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
MAX_SIZE=512000

# 循环处理每个仓库
for i in "${!GIT_URLS[@]}"; do
  USERNAME=$(echo ${GIT_URLS[i]} | awk -F'/' '{print $4}')
  git config --global user.name "${USERNAME}"
  git config --global user.email "${GIT_EMAILS[i]}"

  echo "开始处理仓库：${GIT_URLS[i]}"

  # REPO_DIR="$(mktemp -d)"
  REPO_DIR="/tmp/repo-${USERNAME}"
  if [ -d "${REPO_DIR}" ]; then
    echo "目录 ${REPO_DIR} 已存在，跳过克隆操作"
  else
    git clone https://${GIT_TOKENS[i]}@${GIT_URLS[i]#https://} "${REPO_DIR}"
    CLONE_EXIT_CODE=$?
    if [ $CLONE_EXIT_CODE -ne 0 ]; then
      echo "克隆仓库失败，退出码：$CLONE_EXIT_CODE"
      continue
    fi
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
  if [ -f /tmp/commitAll.txt ]; then 
    if [ $(stat -c%s "/tmp/commitAll.txt") -gt $MAX_SIZE ]; then
      > /tmp/commitAll.txt
    fi
    sed -i "1i提交时间： $DATE, 用户名： ${USERNAME}" /tmp/commitAll.txt
  else
    echo 提交时间： $DATE, 用户名： ${USERNAME} >> /tmp/commitAll.txt
  fi

  git add .
  git commit -m "test: add now time - $DATE"
  git push origin main
  PUSH_EXIT_CODE=$?
  if [ $PUSH_EXIT_CODE -ne 0 ]; then
    echo "推送更改失败，退出码：$PUSH_EXIT_CODE"
    continue
  fi

  echo "仓库：${GIT_URLS[i]}处理完成"

  rm -rf "${REPO_DIR}"
  
  cd ~/
  
done

generate_autodel() {
  cat > auto_del.sh << EOF
while true; do
  rm -rf /app/.git
  sleep 5
done
EOF
}

generate_autodel