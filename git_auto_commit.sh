#!/bin/bash

# 配置
IFS=',' read -ra GIT_URLS <<< "${GIT_URL}"
IFS=',' read -ra GIT_TOKENS <<< "${GIT_TOKEN}"
IFS=',' read -ra GIT_USERNAMES <<< "${GIT_USERNAME}"
IFS=',' read -ra GIT_EMAILS <<< "${GIT_EMAIL}"
DATE=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")

# 循环处理每个仓库
for i in "${!GIT_URLS[@]}"; do

  USERNAME = ${GIT_USERNAMES[i]}
  EMAIL = ${GIT_EMAILS[i]}
  PATH = repo-$USERNAME
  # 设置git配置
  git config --global user.name "$USERNAME"
  git config --global user.email "$EMAIL"


  echo "开始处理仓库：${GIT_URLS[i]}"

  # 克隆仓库
  if [ ! -d "./$PATH" ]; then
    git clone https://${GIT_TOKENS[i]}@${GIT_URLS[i]#https://} "$PATH"
    refresh
  fi

  cd "$PATH"

  # 创建或更新commit.txt文件
  if [ -f ../commit.txt ]; then 
    sed -i "1i提交时间： $DATE, 用户名： $USERNAME" ../commit.txt
  else
    echo 提交时间： $DATE, 用户名： $USERNAME >> ../commit.txt
  fi

  # 添加所有更改
  git add .

  # 提交更改
  git commit -m "test: add now time - $DATE"

  # 推送更改
  git push origin main


  echo "仓库：${GIT_URLS[i]}处理完成"

  cd ..

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