# AI Integration Setup Guide 🤖

This guide will help you set up AI features in your Umshado wedding planning app.

## 🚀 Quick Start

### 1. Get OpenAI API Key
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (it starts with `sk-`)

### 2. Add API Key to Environment
Add this line to your `.env` file:
```bash
EXPO_PUBLIC_OPENAI_API_KEY=sk-your-api-key-here
```

### 3. Restart Your App
```bash
npx expo start --clear
```

## 🎯 AI Features Available

### 1. **AI Wedding Planner Chat** 💬
- Natural language wedding planning assistance
- Context-aware responses based on your wedding details
- Budget, timeline, and vendor recommendations

### 2. **AI Budget Analyzer** 💰
- Analyzes your spending patterns
- Suggests cost optimizations
- Provides industry comparisons
- Identifies potential savings

### 3. **AI Task Generator** ✅
- Generates personalized wedding planning tasks
- Prioritizes tasks based on timeline
- Estimates time requirements
- Integrates with your existing task system

### 4. **AI Vendor Recommendations** 🏢
- Smart vendor matching based on preferences
- Location and budget-aware suggestions
- Quality predictions based on reviews

### 5. **AI Guest List Optimization** 👥
- Analyzes guest list composition
- Suggests seating arrangements
- Predicts RSVP patterns
- Optimizes guest experience

## 💡 Usage Tips

### For Best Results:
1. **Provide Complete Wedding Details**: The more information you give, the better AI recommendations
2. **Update Regularly**: Re-run AI analysis as your plans evolve
3. **Use Context**: AI responses are tailored to your specific wedding details
4. **Combine Features**: Use multiple AI features together for comprehensive planning

### Example Prompts for AI Chat:
- "Help me plan a wedding for 150 guests in Cape Town with a R50,000 budget"
- "What should I prioritize for a wedding in 6 months?"
- "Suggest vendors for photography in Johannesburg under R8,000"
- "How can I reduce my catering costs without compromising quality?"

## 🔧 Technical Implementation

### AI Service Architecture:
```
lib/ai-service.ts          # Core AI functionality
components/ai/             # AI UI components
├── AIHub.tsx             # Main AI dashboard
├── AIChatAssistant.tsx   # Chat interface
├── AIBudgetAnalyzer.tsx  # Budget analysis
└── AITaskGenerator.tsx   # Task generation
```

### Integration Points:
- **Budget System**: Enhances existing `lib/budget.ts`
- **Task Management**: Integrates with `lib/task-service.ts`
- **Guest Management**: Works with `lib/guest-service.ts`
- **Vendor Marketplace**: Enhances vendor discovery

## 💰 Cost Considerations

### OpenAI API Pricing (as of 2024):
- **GPT-3.5-turbo**: ~$0.002 per 1K tokens
- **Typical wedding chat**: ~$0.01-0.05 per conversation
- **Budget analysis**: ~$0.02-0.10 per analysis
- **Task generation**: ~$0.01-0.03 per generation

### Estimated Monthly Costs:
- **Light usage** (10 couples): $5-15/month
- **Medium usage** (50 couples): $25-75/month
- **Heavy usage** (200+ couples): $100-300/month

## 🛡️ Privacy & Security

### Data Handling:
- Wedding data stays in your Supabase database
- Only relevant context sent to OpenAI
- No personal information shared
- API calls are encrypted

### Best Practices:
- Monitor API usage regularly
- Set usage limits in OpenAI dashboard
- Review AI responses before implementing
- Keep API keys secure

## 🚨 Troubleshooting

### Common Issues:

1. **"API Key not found"**
   - Check `.env` file has correct key
   - Restart Expo with `--clear`
   - Verify key starts with `sk-`

2. **"AI responses are generic"**
   - Ensure wedding details are complete
   - Check if wedding data is loading properly
   - Try more specific prompts

3. **"Budget analysis fails"**
   - Verify budget data exists
   - Check if wedding ID is valid
   - Ensure internet connection

4. **"Tasks not generating"**
   - Check wedding date is set
   - Verify guest count is specified
   - Ensure location is provided

## 🔮 Future Enhancements

### Planned Features:
- **Image Analysis**: Analyze inspiration photos for style matching
- **Voice Assistant**: Voice-based wedding planning
- **Predictive Analytics**: Predict wedding success factors
- **Smart Notifications**: AI-powered reminder system
- **Multi-language Support**: Support for multiple languages

### Advanced AI Features:
- **Sentiment Analysis**: Analyze vendor reviews automatically
- **Price Prediction**: Predict vendor pricing trends
- **Timeline Optimization**: AI-optimized wedding day schedule
- **Risk Assessment**: Identify potential planning risks

## 📞 Support

If you encounter issues:
1. Check this guide first
2. Review console logs for errors
3. Verify API key and permissions
4. Test with simple prompts first

## 🎉 Ready to Use!

Once you've added your OpenAI API key, the AI features will be available in the new "AI Assistant" tab in your app. Start with the chat feature to get familiar with the AI capabilities!

---

**Note**: AI features are optional and won't affect your app's core functionality if not configured. The app will gracefully handle missing API keys.
