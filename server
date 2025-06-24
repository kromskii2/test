const TelegramBot = require('node-telegram-bot-api');
const token = 'YOUR_BOT_TOKEN';
const bot = new TelegramBot(token, { polling: true });

// Хранилище состояний пользователей
const userStates = new Map();

// Генератор случайных математических примеров
function generateMathProblem() {
    const operations = ['+', '-', '*'];
    const a = Math.floor(Math.random() * 10) + 1;
    const b = Math.floor(Math.random() * 10) + 1;
    const op = operations[Math.floor(Math.random() * operations.length)];
    
    let problem, answer;
    switch(op) {
        case '+': 
            problem = `${a} + ${b}`;
            answer = a + b;
            break;
        case '-': 
            problem = `${a} - ${b}`;
            answer = a - b;
            break;
        case '*': 
            problem = `${a} * ${b}`;
            answer = a * b;
            break;
    }
    return { problem, answer };
}

// Обработчик новых участников группы
bot.on('new_chat_members', async (msg) => {
    const chatId = msg.chat.id;
    
    for(const user of msg.new_chat_members) {
        if(user.is_bot) continue;

        const userId = user.id;
        const userKey = `${chatId}_${userId}`;
        
        // Генерируем CAPTCHA
        const { problem, answer } = generateMathProblem();
        
        // Сохраняем состояние
        userStates.set(userKey, {
            attempts: 3,
            answer,
            restrictionTimer: null,
            deletionTimer: null
        });

        // Устанавливаем ограничения (15 минут)
        try {
            await bot.restrictChatMember(chatId, userId, {
                permissions: {
                    can_send_messages: false,
                    can_send_media_messages: false,
                    can_send_other_messages: false,
                    can_add_web_page_previews: false
                },
                until_date: Math.floor(Date.now()/1000) + 900 // 15 минут
            });
        } catch(e) {
            console.error('Ошибка ограничения:', e);
        }

        // Отправляем CAPTCHA
        const captchaMessage = await bot.sendMessage(
            chatId,
            `👋 Привет, ${user.first_name}! Чтобы остаться в группе, реши пример:\n\n${problem} = ?\n\nУ тебя 3 попытки!`,
            { reply_to_message_id: msg.message_id }
        );

        // Устанавливаем таймер удаления (30 минут)
        const deletionTimer = setTimeout(async () => {
            if(userStates.has(userKey)) {
                try {
                    await bot.banChatMember(chatId, userId);
                    await bot.unbanChatMember(chatId, userId);
                    bot.deleteMessage(chatId, captchaMessage.message_id);
                } catch(e) {
                    console.error('Ошибка удаления:', e);
                }
                userStates.delete(userKey);
            }
        }, 30 * 60 * 1000);

        // Обновляем состояние
        const userState = userStates.get(userKey);
        userState.deletionTimer = deletionTimer;
        userState.messageId = captchaMessage.message_id;
    }
});

// Обработчик ответов
bot.on('message', async (msg) => {
    if(!msg.text || !msg.from) return;
    
    const userId = msg.from.id;
    const chatId = msg.chat.id;
    const userKey = `${chatId}_${userId}`;
    
    if(!userStates.has(userKey)) return;
    
    const state = userStates.get(userKey);
    const userAnswer = parseInt(msg.text.trim());
    
    if(isNaN(userAnswer)) return;

    if(userAnswer === state.answer) {
        // Правильный ответ
        bot.sendMessage(chatId, `✅ Верно! Добро пожаловать, ${msg.from.first_name}!`);
        
        // Снимаем ограничения
        try {
            await bot.restrictChatMember(chatId, userId, {
                permissions: {
                    can_send_messages: true,
                    can_send_media_messages: true,
                    can_send_other_messages: true,
                    can_add_web_page_previews: true
                }
            });
        } catch(e) {
            console.error('Ошибка снятия ограничений:', e);
        }
        
        // Удаляем сообщение с CAPTCHA
        bot.deleteMessage(chatId, state.messageId);
        
        // Очищаем таймеры
        clearTimeout(state.restrictionTimer);
        clearTimeout(state.deletionTimer);
        userStates.delete(userKey);
    } else {
        // Неправильный ответ
        state.attempts--;
        
        if(state.attempts > 0) {
            bot.sendMessage(
                chatId,
                `❌ Неверно! Осталось попыток: ${state.attempts}\nПопробуй еще раз:`,
                { reply_to_message_id: msg.message_id }
            );
        } else {
            // Попытки закончились
            bot.sendMessage(
                chatId,
                `⛔ ${msg.from.first_name}, попытки исчерпаны! Ты будешь удален из группы.`,
                { reply_to_message_id: msg.message_id }
            );
            
            // Удаляем пользователя
            try {
                await bot.banChatMember(chatId, userId);
                await bot.unbanChatMember(chatId, userId);
            } catch(e) {
                console.error('Ошибка удаления:', e);
            }
            
            // Удаляем сообщение с CAPTCHA
            bot.deleteMessage(chatId, state.messageId);
            
            // Очищаем таймеры
            clearTimeout(state.restrictionTimer);
            clearTimeout(state.deletionTimer);
            userStates.delete(userKey);
        }
    }
});
