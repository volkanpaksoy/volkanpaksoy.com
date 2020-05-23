using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConvertMarkdown
{
    public class Converter
    {
        public void Run(string rootFolderPath)
        {
            DirectoryInfo rootDirectory = new DirectoryInfo(rootFolderPath);
            FileInfo[] markdownFileList = rootDirectory.GetFiles("*.markdown");
            foreach (var markdownFile in markdownFileList)
            {
                ConvertFile(markdownFile.FullName, string.Format("{0}.output", markdownFile.FullName));
            }
        }

        public void ConvertFile(string inputFilePath, string outputFilePath)
        {
            // FileInfo inputFile = new FileInfo(filePath);
            if (!File.Exists(inputFilePath))
            {
                throw new ArgumentException("Input file does not exist");
            }

            // Extract old header data
            string originalData = File.ReadAllText(inputFilePath);
            int headerStartIndex = originalData.IndexOf("---");
            int headerEndIndex = originalData.IndexOf("---", 3);
            string oldHeader = originalData.Substring(headerStartIndex, headerEndIndex-headerStartIndex + 3);

            // Skip already converted ones
            if (oldHeader.Contains("comments: true"))
            {
                return;
            }
            
            // Populate header template with the data
            string newHeader = GetNewHeaderTemplate();
            newHeader = newHeader.Replace("@TITLE", GetTitle(oldHeader));
            newHeader = newHeader.Replace("@DATE", GetDate(oldHeader));
            newHeader = newHeader.Replace("@CATEGORIES", GetCategories(oldHeader));

            string newData = originalData.Replace(oldHeader, newHeader);
            File.WriteAllText(outputFilePath, newData);

            File.Delete(inputFilePath);
            // File.Move(outputFilePath, inputFilePath);
        }

        private string GetTitle(string header)
        {
            int startIndex = header.IndexOf("title:") + 7;
            int endIndex = header.IndexOf("date:");
            return header.Substring(startIndex, endIndex - startIndex).TrimEnd('\n').TrimEnd('\r');
        }

        private string GetDate(string header)
        {
            int startIndex = header.IndexOf("date:") + 6;
            int endIndex = header.IndexOf("categories:");
            return header.Substring(startIndex, endIndex - startIndex).TrimEnd('\n').TrimEnd('\r');
        }

        private string GetCategories(string header)
        {
            int startIndex = header.IndexOf("categories:") + 12;
            int endIndex = header.IndexOf("tags:");
            string categories = header.Substring(startIndex, endIndex - startIndex);
            return string.Join(", ", categories.Trim().Split("-".ToCharArray(), StringSplitOptions.RemoveEmptyEntries).Select(s => s.Trim(',').Trim()).ToArray());
        }

        private string GetNewHeaderTemplate()
        {
            return @"---
layout: post
title: @TITLE
date: @DATE
categories: [@CATEGORIES]
comments: true
---";
        }
    }

    class Program
    {
        private const string ROOT_FOLDER = @"path/to/posts";

        static void Main(string[] args)
        {
            var converter = new Converter();
            converter.Run(ROOT_FOLDER);
        }
    }
}
