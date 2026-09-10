#!/bin/sh
# restart-uat.sh — 重启 UAT Docker 环境, 使 .env.uat 的参数变更生效 (macOS)
#
# 用法:
#   scripts/restart-uat.sh
#
# 步骤:
#   1. 重建 gaap-web 镜像 (NEXT_PUBLIC_* 是 Docker 构建参数, 只有 rebuild 才生效)
#   2. 强制重建所有容器 (.env.uat 通过 env_file 在容器创建时注入, 必须 recreate)
#   3. 等待健康检查通过
#
# 说明:
#   - gaap-api 只读取运行时 env, 不需要 rebuild, 仅随容器重建生效
#   - postgres/redis/rabbitmq 数据在 named volume 中, 重建不丢数据

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_dir=$(CDPATH= cd -- "${script_dir}/.." && pwd)

env_file="${project_dir}/.env.uat"
compose_file="${project_dir}/docker-compose.uat.yml"

[ -f "${env_file}" ] || { printf 'error: %s not found\n' "${env_file}" >&2; exit 1; }
[ -f "${compose_file}" ] || { printf 'error: %s not found\n' "${compose_file}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { printf 'error: docker not found in PATH\n' >&2; exit 1; }

cd "${project_dir}"

compose() {
  docker compose --env-file "${env_file}" -f "${compose_file}" "$@"
}

printf '==> 1/3 重建 gaap-web 镜像 (应用 NEXT_PUBLIC_* 构建参数)...\n'
compose build gaap-web

printf '==> 2/3 强制重建所有容器 (env_file 参数变更)...\n'
compose up -d --force-recreate

printf '==> 3/3 等待健康检查通过...\n'
compose up -d --wait

compose ps

printf '\nUAT 环境已重启, .env.uat 参数已生效.\n'
