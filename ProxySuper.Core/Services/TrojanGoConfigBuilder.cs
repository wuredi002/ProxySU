using System;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ProxySuper.Core.Models.Projects;
using ProxySuper.Core.Templates;
using System.IO;

namespace ProxySuper.Core.Services
{
    public class TrojanGoConfigBuilder
    {
        public static readonly int WebPort = 8088;

        public static readonly string TrojanGoSettingPath = TrojanGoTemplates.TrojanGoJson; 

        public static readonly string CaddyFilePath = TrojanGoTemplates.BaseCaddyfile; 

        public static string BuildTrojanGoConfig(TrojanGoSettings parameters)
        {
            var jsonStr = TrojanGoSettingPath;
            var settings = JToken.FromObject(JsonConvert.DeserializeObject(jsonStr));

            settings["remote_port"] = WebPort;
            settings["password"][0] = parameters.Password;
            settings["ssl"]["sni"] = parameters.Domain;

            if (parameters.EnableWebSocket)
            {
                settings["websocket"]["enabled"] = true;
                settings["websocket"]["path"] = NormalizeWebSocketPath(parameters.WebSocketPath);
                settings["websocket"]["host"] = parameters.Domain;
            }

            return JsonConvert.SerializeObject(settings, Formatting.Indented, new JsonSerializerSettings()
            {
                NullValueHandling = NullValueHandling.Ignore
            });
        }

        private static string NormalizeWebSocketPath(string path)
        {
            var normalized = (path ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(normalized))
            {
                return "/";
            }

            if (!normalized.StartsWith("/"))
            {
                normalized = "/" + normalized;
            }

            if (normalized.Contains(" ") || normalized.Contains("\r") || normalized.Contains("\n")
                || normalized.Contains("?") || normalized.Contains("#"))
            {
                throw new ArgumentException("Trojan-Go WebSocket 路径不能包含空格、换行、查询参数或片段。", nameof(path));
            }

            return normalized;
        }

        public static string BuildCaddyConfig(TrojanGoSettings parameters, bool useCustomWeb = false)
        {
            var caddyStr = CaddyFilePath;
            caddyStr = caddyStr.Replace("##domain##", parameters.Domain);
            caddyStr = caddyStr.Replace("##port##", WebPort.ToString());

            if (!useCustomWeb && !string.IsNullOrEmpty(parameters.MaskDomain))
            {
                if (!Uri.TryCreate(parameters.MaskDomain.Trim(), UriKind.Absolute, out var maskUri)
                    || (maskUri.Scheme != Uri.UriSchemeHttp && maskUri.Scheme != Uri.UriSchemeHttps)
                    || string.IsNullOrWhiteSpace(maskUri.Host))
                {
                    throw new ArgumentException("伪装地址必须是有效的 http:// 或 https:// URL。", nameof(parameters.MaskDomain));
                }

                var prefix = maskUri.Scheme + "://";
                var domain = maskUri.IsDefaultPort ? maskUri.Host : maskUri.Host + ":" + maskUri.Port;

                caddyStr = caddyStr.Replace("##reverse_proxy##", $"reverse_proxy {prefix}{domain} {{ \n        header_up Host {maskUri.Host} \n    }}");
            }
            else
            {
                caddyStr = caddyStr.Replace("##reverse_proxy##", "");
            }

            return caddyStr;
        }
    }

}
