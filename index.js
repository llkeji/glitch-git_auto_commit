const express = require("express");
const app = express();
const port = 3000;
const PROJECT_DOMAIN = process.env.PROJECT_DOMAIN;
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");

app.get("/", function (req, res) {
    let cmdStr = "echo 'Hello, World!'";
    exec(cmdStr, function (err, stdout, stderr) {
      if (err) {
        res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
      } else {
        res.type("html").send("<pre>Powered by Aurora\n" + "</pre>");
      }
    });
  });


app.get("/git_commit", function (req, res) {
    keepaliveAutoCommit().then(r => {
      let cmdStr = "cat /tmp/commitAll.txt" ;
  
      exec(cmdStr, function (err, stdout, stderr) {
        if (err) {
          res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
        } else {
          const result = organizeSubmissions(stdout);
          res.type("html").send("<pre>" + JSON.stringify(result, null, 2) + "</pre>");
        }
      });
    }).catch((err) => {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    })
  });

app.use(
    "/" + "*", 
    createProxyMiddleware({
        target: "http://127.0.0.1:8080/", 
        changeOrigin: false, 
        ws: true,
        logLevel: "error",
        onProxyReq: function onProxyReq(proxyReq, req, res) { }
    })
);

function keepalive() {
  exec("pgrep -laf app.js", function (err, stdout, stderr) {
    // 1.查后台系统进程，保持唤醒
    if (stdout.includes("./app.js")) {
      console.log("Aurora 正在运行");
    } else {
      //Argo 未运行，命令行调起
      exec("bash aurora.sh 2>&1 &", function (err, stdout, stderr) {
        if (err) {
          console.log("保活-调起Aurora-命令行执行错误:" + err);
        } else {
          console.log("保活-调起Aurora-命令行执行成功!");
        }
      });
    }
  });
}
setInterval(keepalive, 9 * 1000);

function keep_argo_alive() {
    if (!process.env.ARGO_AUTH) {
      console.log("未设置 ARGO_AUTH，跳过启动 Cloudflred！");
      return; 
    }
    exec("pgrep -laf cloudflared", function (err, stdout, stderr) {
      // 1.查后台系统进程，保持唤醒
      if (stdout.includes("./cloudflared tunnel")) {
        console.log("Argo 正在运行");
      } else {
        //Argo 未运行，命令行调起
        exec("bash argo.sh 2>&1 &", function (err, stdout, stderr) {
          if (err) {
            console.log("保活-调起Argo-命令行执行错误:" + err);
          } else {
            console.log("保活-调起Argo-命令行执行成功!");
          }
        });
      }
    });
  }
  setInterval(keep_argo_alive, 30 * 1000);



function keepaliveAutoCommit() {
  return new Promise((resolve, reject) => {
    exec("bash git_auto_commit.sh 2>&1 &", function (err, stdout, stderr) {
      if (err) {
        console.error("保活-调起git_auto_commit-命令行执行错误:", err);
        reject(err);
      } else {
        console.log("保活-调起git_auto_commit-命令行执行成功!");
        resolve(true);
      }
    });
  });
}
// setInterval(keepaliveAutoCommit, 10800 * 1000);


function organizeSubmissions(str) {
  const submissions = str.split('\n').filter(c => c);
  const userCommits = {};
  submissions.forEach(submission => {
    const [timePart, userPart] = submission.split(', 用户名： ');
    const [date, time] = timePart.replace('提交时间： ', '').split(' ');
    const username = userPart.trim();

    if (!userCommits[username]) {
      userCommits[username] = { commit: {}, total: 0 };
    }

    if (!userCommits[username].commit[date]) {
      userCommits[username].commit[date] = [];
    }

    userCommits[username].commit[date].push(`${date} ${time}`);
    userCommits[username].total += 1;
  });

  for (const user in userCommits) {
    for (const date in userCommits[user].commit) {
      userCommits[user].commit[date].sort().reverse();
    }
  }

  return userCommits;
}

app.listen(port, () => console.log(`Example app listening on port ${port}!`));